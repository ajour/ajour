use std::mem;
use std::ptr;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::mpsc::{sync_channel, SyncSender};
use std::thread;

use once_cell::sync::OnceCell;
use winapi::shared::windef::{HWND, POINT};
use winapi::um::libloaderapi::GetModuleHandleW;
use winapi::um::shellapi::{
    Shell_NotifyIconW, NIF_ICON, NIF_INFO, NIF_MESSAGE, NIF_TIP, NIIF_NONE, NIIF_NOSOUND, NIM_ADD,
    NIM_DELETE, NIM_MODIFY, NOTIFYICONDATAW,
};
use winapi::um::wingdi::{CreateSolidBrush, RGB};
use winapi::um::winuser::{
    CreatePopupMenu, CreateWindowExW, DefWindowProcW, DestroyMenu, DestroyWindow, DispatchMessageW,
    EnumWindows, GetCursorPos, GetMessageW, GetWindowLongPtrW, GetWindowTextW,
    GetWindowThreadProcessId, InsertMenuW, LoadIconW, MessageBoxW, PostMessageW, PostQuitMessage,
    RegisterClassExW, SendMessageW, SetFocus, SetForegroundWindow, SetMenuDefaultItem,
    SetWindowLongPtrW, ShowWindow, TrackPopupMenu, TranslateMessage, CREATESTRUCTW, GWLP_USERDATA,
    MAKEINTRESOURCEW, MB_ICONINFORMATION, MB_OK, MF_BYPOSITION, MF_GRAYED, MF_SEPARATOR, MF_STRING,
    SW_HIDE, TPM_LEFTALIGN, TPM_NONOTIFY, TPM_RETURNCMD, TPM_RIGHTBUTTON, WM_APP, WM_CLOSE,
    WM_COMMAND, WM_CREATE, WM_DESTROY, WM_INITMENUPOPUP, WM_LBUTTONDBLCLK, WM_RBUTTONUP,
    WNDCLASSEXW, WS_EX_NOACTIVATE,
};
use winapi::{
    shared::minwindef::{BOOL, LOWORD, LPARAM, LRESULT, UINT, WPARAM},
    um::winuser::SW_SHOW,
};

use crate::localization::localized_string;
use crate::log_error;

mod autostart;

pub static SHOULD_EXIT: AtomicBool = AtomicBool::new(false);
pub static GUI_VISIBLE: AtomicBool = AtomicBool::new(false);
pub static TRAY_SENDER: OnceCell<SyncSender<TrayMessage>> = OnceCell::new();

const ID_ABOUT: u16 = 2000;
const ID_TOGGLE_WINDOW: u16 = 2001;
const ID_EXIT: u16 = 2002;
const WM_HIDE_GUI: u32 = WM_APP + 1;

pub enum TrayMessage {
    Enable,
    Disable,
    CloseToTray,
    TrayCreated(WindowHandle),
    ToggleAutoStart(bool),
}

#[derive(Debug)]
struct TrayState {
    gui_handle: Option<HWND>,
    gui_hidden: bool,
    about_shown: bool,
    close_gui: bool,
    show_balloon: bool,
}

unsafe impl Send for TrayState {}
unsafe impl Sync for TrayState {}

pub struct WindowHandle(HWND);

unsafe impl Send for WindowHandle {}
unsafe impl Sync for WindowHandle {}

#[macro_export]
macro_rules! str_to_wide {
    ($str:expr) => {{
        $str.encode_utf16()
            .chain(std::iter::once(0))
            .collect::<Vec<_>>()
    }};
}

pub fn spawn_sys_tray(enabled: bool, start_closed_to_tray: bool) {
    thread::spawn(move || {
        let (sender, receiver) = sync_channel(1);
        let _ = TRAY_SENDER.set(sender);

        // Stores the window handle so we can post messages to its queue
        let mut window: Option<WindowHandle> = None;

        // Spawn tray initially if enabled
        if enabled {
            unsafe { create_window(false, start_closed_to_tray) };
        }

        // Make GUI visible if we don't start to tray
        if !start_closed_to_tray {
            GUI_VISIBLE.store(true, Ordering::Relaxed);
        }

        while let Ok(msg) = receiver.recv() {
            match msg {
                TrayMessage::Enable => unsafe {
                    if window.is_none() {
                        create_window(true, false);
                    }
                },
                TrayMessage::Disable => unsafe {
                    if let Some(window) = window.take() {
                        PostMessageW(window.0, WM_CLOSE, 1, 0);
                    }
                },
                TrayMessage::CloseToTray => unsafe {
                    if let Some(window) = window.as_ref() {
                        PostMessageW(window.0, WM_HIDE_GUI, 0, 0);
                    }
                },
                TrayMessage::TrayCreated(win) => {
                    window = Some(win);
                }
                TrayMessage::ToggleAutoStart(enabled) => unsafe {
                    if let Err(e) = autostart::toggle_autostart(enabled) {
                        log_error(&e);
                    }
                },
            }
        }
    });
}

unsafe fn create_window(show_balloon: bool, gui_hidden: bool) {
    thread::spawn(move || {
        let mut tray_state = TrayState {
            gui_handle: None,
            gui_hidden,
            about_shown: false,
            close_gui: false,
            show_balloon,
        };

        // Keep searching for window handle until its found
        while tray_state.gui_handle.is_none() {
            EnumWindows(Some(enum_proc), &mut tray_state as *mut _ as LPARAM);
        }

        let h_instance = GetModuleHandleW(ptr::null());

        let class_name = str_to_wide!("Ajour Tray");

        let mut class = mem::zeroed::<WNDCLASSEXW>();
        class.cbSize = mem::size_of::<WNDCLASSEXW>() as u32;
        class.lpfnWndProc = Some(window_proc);
        class.hInstance = h_instance;
        class.lpszClassName = class_name.as_ptr();
        class.hbrBackground = CreateSolidBrush(RGB(0, 77, 128));

        RegisterClassExW(&class);

        let hwnd = CreateWindowExW(
            WS_EX_NOACTIVATE,
            class_name.as_ptr(),
            ptr::null(),
            0,
            0,
            0,
            0,
            0,
            ptr::null_mut(),
            ptr::null_mut(),
            h_instance,
            &mut tray_state as *mut _ as *mut std::ffi::c_void,
        );

        // Send window handle back to main loop so we can post messages to it
        let _ = TRAY_SENDER
            .get()
            .unwrap()
            .try_send(TrayMessage::TrayCreated(WindowHandle(hwnd)));

        let mut msg = mem::zeroed();
        while GetMessageW(&mut msg, ptr::null_mut(), 0, 0) != 0 {
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }

        if tray_state.close_gui {
            // WM_QUIT was sent, which was triggered by the Exit button. Close entire program.
            SHOULD_EXIT.store(true, Ordering::Relaxed);

            // Activate window to force event loop to run / see that it should now close
            SetForegroundWindow(tray_state.gui_handle.unwrap());
        }
    });
}

unsafe fn add_icon(hwnd: HWND) {
    let h_instance = GetModuleHandleW(ptr::null());

    let icon_handle = LoadIconW(h_instance, MAKEINTRESOURCEW(0x101));

    let mut tooltip_array = [0u16; 128];
    let tooltip = "Ajour";
    let mut tooltip = tooltip.encode_utf16().collect::<Vec<_>>();
    tooltip.extend(vec![0; 128 - tooltip.len()]);
    tooltip_array.swap_with_slice(&mut tooltip[..]);

    let mut icon_data: NOTIFYICONDATAW = mem::zeroed();
    icon_data.cbSize = mem::size_of::<NOTIFYICONDATAW>() as u32;
    icon_data.hWnd = hwnd;
    icon_data.uID = 1;
    icon_data.uCallbackMessage = WM_APP;
    icon_data.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
    icon_data.hIcon = icon_handle;
    icon_data.szTip = tooltip_array;

    Shell_NotifyIconW(NIM_ADD, &mut icon_data);
}

unsafe fn display_balloon_message(hwnd: HWND, message: &str) {
    let mut info = [0u16; 256];
    let message = str_to_wide!(message);

    for (idx, b) in message[0..message.len().min(255)].iter().enumerate() {
        info[idx] = *b;
    }

    let mut icon_data: NOTIFYICONDATAW = mem::zeroed();
    icon_data.cbSize = mem::size_of::<NOTIFYICONDATAW>() as u32;
    icon_data.hWnd = hwnd;
    icon_data.uID = 1;
    icon_data.uFlags = NIF_INFO;
    icon_data.szInfo = info;
    icon_data.dwInfoFlags = NIIF_NONE | NIIF_NOSOUND;

    Shell_NotifyIconW(NIM_MODIFY, &mut icon_data);
}

unsafe fn remove_icon(hwnd: HWND) {
    let mut icon_data: NOTIFYICONDATAW = mem::zeroed();
    icon_data.cbSize = mem::size_of::<NOTIFYICONDATAW>() as u32;
    icon_data.hWnd = hwnd;
    icon_data.uID = 1;

    Shell_NotifyIconW(NIM_DELETE, &mut icon_data);
}

unsafe fn show_popup_menu(hwnd: HWND, state: &TrayState) {
    let menu = CreatePopupMenu();

    let hidden = state.gui_hidden;

    let mut about = str_to_wide!(localized_string("about"));
    let mut toggle = str_to_wide!(if hidden {
        localized_string("open-ajour")
    } else {
        localized_string("hide-ajour")
    });
    let mut exit = str_to_wide!(localized_string("exit"));

    InsertMenuW(
        menu,
        0,
        MF_BYPOSITION | MF_STRING,
        ID_TOGGLE_WINDOW as usize,
        toggle.as_mut_ptr(),
    );

    InsertMenuW(
        menu,
        1,
        MF_BYPOSITION | MF_STRING,
        ID_ABOUT as usize,
        about.as_mut_ptr(),
    );

    InsertMenuW(menu, 2, MF_SEPARATOR | MF_GRAYED, 0, ptr::null_mut());

    InsertMenuW(
        menu,
        3,
        MF_BYPOSITION | MF_STRING,
        ID_EXIT as usize,
        exit.as_mut_ptr(),
    );

    SetMenuDefaultItem(menu, ID_TOGGLE_WINDOW as u32, 0);
    SetFocus(hwnd);
    SendMessageW(hwnd, WM_INITMENUPOPUP, menu as usize, 0);

    let mut point: POINT = mem::zeroed();
    GetCursorPos(&mut point);

    let cmd = TrackPopupMenu(
        menu,
        TPM_LEFTALIGN | TPM_RIGHTBUTTON | TPM_RETURNCMD | TPM_NONOTIFY,
        point.x,
        point.y,
        0,
        hwnd,
        ptr::null_mut(),
    );

    SendMessageW(hwnd, WM_COMMAND, cmd as usize, 0);

    DestroyMenu(menu);
}

unsafe fn show_about() {
    let mut title = str_to_wide!("About");

    let msg = format!(
        "Ajour - {}\n\nCopyright © 2020-2021 Casper Rogild Storm",
        env!("CARGO_PKG_VERSION")
    );

    let mut msg = str_to_wide!(msg);

    MessageBoxW(
        ptr::null_mut(),
        msg.as_mut_ptr(),
        title.as_mut_ptr(),
        MB_ICONINFORMATION | MB_OK,
    );
}

unsafe extern "system" fn window_proc(
    hwnd: HWND,
    msg: UINT,
    wparam: WPARAM,
    lparam: LPARAM,
) -> LRESULT {
    let mut state: &mut TrayState;

    if msg == WM_CREATE {
        let create_struct = &*(lparam as *const CREATESTRUCTW);
        state = &mut *(create_struct.lpCreateParams as *mut TrayState);
        SetWindowLongPtrW(hwnd, GWLP_USERDATA, state as *mut _ as LPARAM);

        add_icon(hwnd);

        if state.show_balloon {
            display_balloon_message(hwnd, "Running from Tray...");
        }

        return 0;
    } else {
        let ptr = GetWindowLongPtrW(hwnd, GWLP_USERDATA);
        state = &mut *(ptr as *mut TrayState);
    }

    match msg {
        WM_CLOSE => {
            // We send wparam as 1 when disabling tray from gui, and we don't want
            // to shut down gui. Otherwise tray is closing because we selected Exit
            // from tray icon
            if wparam == 0 {
                state.close_gui = true;
            }

            remove_icon(hwnd);

            DestroyWindow(hwnd);
        }
        WM_DESTROY => {
            PostQuitMessage(0);
        }
        WM_COMMAND => {
            match LOWORD(wparam as u32) {
                ID_ABOUT => {
                    // Don't show if already up
                    if !state.about_shown {
                        state.about_shown = true;

                        show_about();

                        state.about_shown = false;

                        return 0;
                    }
                }
                ID_TOGGLE_WINDOW => {
                    state.gui_hidden = !state.gui_hidden;
                    ShowWindow(
                        *state.gui_handle.as_ref().unwrap(),
                        if state.gui_hidden { SW_HIDE } else { SW_SHOW },
                    );
                    SetForegroundWindow(*state.gui_handle.as_ref().unwrap());

                    return 0;
                }
                ID_EXIT => {
                    PostMessageW(hwnd, WM_CLOSE, 0, 0);
                    return 0;
                }
                _ => {}
            }
        }
        WM_APP => match lparam as u32 {
            WM_LBUTTONDBLCLK => {
                state.gui_hidden = !state.gui_hidden;
                ShowWindow(
                    *state.gui_handle.as_ref().unwrap(),
                    if state.gui_hidden { SW_HIDE } else { SW_SHOW },
                );
                SetForegroundWindow(*state.gui_handle.as_ref().unwrap());

                return 0;
            }
            WM_RBUTTONUP => {
                SetForegroundWindow(hwnd);
                show_popup_menu(hwnd, state);

                return 0;
            }
            _ => {}
        },
        WM_HIDE_GUI => {
            state.gui_hidden = true;
            ShowWindow(*state.gui_handle.as_ref().unwrap(), SW_HIDE);
            SetForegroundWindow(*state.gui_handle.as_ref().unwrap());

            return 0;
        }
        _ => {}
    }

    DefWindowProcW(hwnd, msg, wparam, lparam)
}

unsafe extern "system" fn enum_proc(hwnd: HWND, lparam: LPARAM) -> BOOL {
    let mut state = &mut *(lparam as *mut TrayState);

    let mut id = mem::zeroed();
    GetWindowThreadProcessId(hwnd, &mut id);

    if id == std::process::id() {
        let mut title = [0u16; 12];
        let read_len = GetWindowTextW(hwnd, title.as_mut_ptr(), 12);
        let title = String::from_utf16_lossy(&title[0..read_len.min(12) as usize]);

        if title == "Ajour" {
            state.gui_handle = Some(hwnd);

            return 0;
        }
    }

    1
}
