use std::ffi::c_void;
use std::path::PathBuf;

use ajour_core::fs::PersistentData;
use serde::{Deserialize, Serialize};
use winapi::{
    shared::winerror::WAIT_TIMEOUT,
    um::{
        processthreadsapi::{GetCurrentProcess, GetCurrentProcessId, OpenProcess},
        synchapi::WaitForSingleObject,
        winbase::QueryFullProcessImageNameW,
        winnt::{PROCESS_QUERY_LIMITED_INFORMATION, SYNCHRONIZE},
    },
};

#[derive(Debug, Serialize, Deserialize)]
struct Process {
    pid: u32,
    name: String,
}

impl PersistentData for Process {
    fn relative_path() -> PathBuf {
        PathBuf::from("pid")
    }
}

pub fn avoid_multiple_instances() {
    if process_already_running() {
        log::info!("Another instance of Ajour is already running. Exiting...");
        std::process::exit(0);
    } else {
        // Otherwise this is the only instance. Save info about this process to the
        // pid file so future launches of Ajour can detect this running process.
        save_current_process_file();
    }
}

fn process_already_running() -> bool {
    let old_process = if let Ok(process) = Process::load() {
        process
    } else {
        return false;
    };

    unsafe {
        let current_pid = GetCurrentProcessId();

        // In case new process somehow got recycled PID of old process
        if current_pid == old_process.pid {
            return false;
        }

        let handle = OpenProcess(
            SYNCHRONIZE | PROCESS_QUERY_LIMITED_INFORMATION,
            0,
            old_process.pid,
        );

        if let Some(name) = get_process_name(handle) {
            if name == old_process.name {
                let status = WaitForSingleObject(handle, 0);

                return status == WAIT_TIMEOUT;
            }
        }
    }

    false
}

fn save_current_process_file() {
    unsafe {
        let handle = GetCurrentProcess();
        let pid = GetCurrentProcessId();

        if let Some(name) = get_process_name(handle) {
            let process = Process { pid, name };

            let _ = process.save();
        }
    }
}

unsafe fn get_process_name(handle: *mut c_void) -> Option<String> {
    let mut size = 256;
    let mut buffer = [0u16; 256];

    let status = QueryFullProcessImageNameW(handle, 0, buffer.as_mut_ptr(), &mut size);

    if status != 0 {
        String::from_utf16(&buffer[..(size as usize).min(buffer.len())]).ok()
    } else {
        None
    }
}
