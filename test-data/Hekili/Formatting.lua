-- Formatting.lua
-- Modified from For all Indents and Purposes, info below.

local addon, ns = ...
local Hekili = _G[ addon ]

--[[ For all Indents and Purposes

Copyright (c) 2007 Kristofer Karlsson <kristofer.karlsson@gmail.com>



Permission is hereby granted, free of charge, to any person obtaining a copy of

this software and associated documentation files (the "Software"), to deal in

the Software without restriction, including without limitation the rights to

use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of

the Software, and to permit persons to whom the Software is furnished to do so,

subject to the following conditions:



The above copyright notice and this permission notice shall be included in all

copies or substantial portions of the Software.



THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR

IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS

FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR

COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER

IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN

CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

]]

--- This is a specialized version of "For All Indents And Purposes", originally
-- by krka <kristofer.karlsson@gmail.com>, modified for Hack by Mud, aka
-- Eric Tetz <erictetz@gmail.com>, and then further modified by Saiket
-- <saiket.wow@gmail.com> for _DevPad.
--
-- Modified by Hekili for Hekili, primarily to protect the "Accept" button
-- functionality in AceConfigDialog driven environments.
--
-- @usage Apply auto-indentation/syntax highlighting to an editbox like this:
--   lib.Enable(Editbox, [TabWidth], [ColorTable], [SuppressIndent]);
-- If TabWidth or ColorTable are omitted, those featues won't be applied.
-- ColorTable should map TokenIDs and string Token values to color codes.
-- @see lib.Tokens

local lib = ns.lib.Format;

local modf = math.modf
local round = ns.round

local UPDATE_INTERVAL = 0.2; -- Time to wait after last keypress before updating

do
  local CursorPosition, CursorDelta;
  --- Callback for gsub to remove unescaped codes.
  local function StripCodeGsub ( Escapes, Code, End )
    if ( #Escapes % 2 == 0 ) then -- Doesn't escape Code
      if ( CursorPosition and CursorPosition >= End - 1 ) then
        CursorDelta = CursorDelta - #Code;
    end
    return Escapes;
    end
  end
  --- Removes a single escape sequence.
  local function StripCode ( Pattern, Text, OldCursor )
    CursorPosition, CursorDelta = OldCursor, 0;
    return Text:gsub( Pattern, StripCodeGsub ),
      OldCursor and CursorPosition + CursorDelta;
  end
  --- Strips Text of all color escape sequences.
  -- @param Cursor  Optional cursor position to keep track of.
  -- @return Stripped text, and the updated cursor position if Cursor was given.
  function lib.StripColors ( Text, Cursor )
    Text, Cursor = StripCode( "(|*)(|[Cc]%x%x%x%x%x%x%x%x)()", Text, Cursor );
    return StripCode( "(|*)(|[Rr])()", Text, Cursor );
  end
end

do
  local Enabled, Updaters = {}, {};

  local CodeCache, ColoredCache = {}, {};
  local NumLinesCache = {};

  local SetTextBackup, GetTextBackup, InsertBackup;
  local GetCursorPositionBackup, SetCursorPositionBackup, HighlightTextBackup;
  --- Reapplies formatting to this editbox using settings from when it was enabled.
  -- @param ForceIndent  If true, forces auto-indent even if the line count didn't
  --   change.  If false, suppress indentation.  If nil, only indent when line count changes.
  -- @return True if text was changed.
  function lib:Update ( ForceIndent )
    if ( not Enabled[ self ] ) then
      return;
    end

    local Colored = GetTextBackup( self );
    if ( ColoredCache[ self ] == Colored ) then
      return;
    end
    local Code, Cursor = lib.StripColors( Colored,
      GetCursorPositionBackup( self ) );

    -- Count lines in text
    local NumLines, IndexLast = 0, 0;
    for Index in Code:gmatch( "[^\r\n]*()" ) do
      if ( IndexLast ~= Index ) then
        NumLines, IndexLast = NumLines + 1, Index;
      end
    end
    if ( ForceIndent == nil and NumLinesCache[ self ] ~= NumLines ) then
      ForceIndent = true; -- Reindent if line count changes
    end
    NumLinesCache[ self ] = NumLines;

    local ColoredNew, Cursor = lib.FormatCode( Code,
      ForceIndent and self.faiap_tabWidth, self.faiap_colorTable, Cursor );
    CodeCache[ self ], ColoredCache[ self ] = Code, ColoredNew;

    if ( Colored ~= ColoredNew ) then
      self.Coloring = true
      SetTextBackup( self, ColoredNew );
      SetCursorPositionBackup( self, Cursor );
      return true;
    end
  end

  --- @return True if successfully disabled for this editbox.
  function lib:Disable ()
    if ( not Enabled[ self ] ) then
      return;
    end
    Enabled[ self ] = false;
    self.GetText, self.SetText, self.Insert = nil;
    self.GetCursorPosition, self.SetCursorPosition, self.HighlightText = nil;

    local Code, Cursor = lib.StripColors( self:GetText(),
      self:GetCursorPosition() );
    self:SetText( Code );
    self:SetCursorPosition( Cursor );

    self:SetMaxBytes( self.faiap_maxBytes );
    self:SetCountInvisibleLetters( self.faiap_countInvisible );
    self.faiap_maxBytes, self.faiap_countInvisible = nil;
    self.faiap_tabWidth, self.faiap_colorTable = nil;
    CodeCache[ self ], ColoredCache[ self ] = nil;
    NumLinesCache[ self ] = nil;
    return true;
  end

  --- Flags the editbox to be reformatted when its contents change.
  local function OnTextChanged ( self, ... )
    if ( Enabled[ self ] ) then
      CodeCache[ self ] = nil;
      local Updater = Updaters[ self ];
      Updater:Stop();
      Updater:Play();
    end
    if ( self.faiap_OnTextChanged ) then
      return self:faiap_OnTextChanged( ... );
    end
  end

  --- Forces a re-indent for this editbox on tab.
  local function OnTabPressed ( self, ... )
    if ( self.faiap_OnTabPressed ) then
      self:faiap_OnTabPressed( ... );
    end
    return lib.Update( self, true );
  end

  --- @return Cached plain text contents.
  local function GetCodeCached ( self )
    local Code = CodeCache[ self ];
    if ( not Code ) then
      Code = lib.StripColors( ( GetTextBackup( self ) ) );
      CodeCache[ self ] = Code;
    end
    return Code;
  end

  --- @return Un-colored text as if FAIAP wasn't there.
  -- @param Raw  True to return fully formatted contents.
  local function GetText( self, Raw )
    if ( Raw ) then
      return GetTextBackup( self );
    else
      return GetCodeCached( self );
    end
  end

  --- Clears cached contents if set directly.
  -- This is necessary because OnTextChanged won't fire immediately or if the
  -- edit box is hidden.
  local function SetText ( self, ... )
    CodeCache[ self ] = nil;
    return SetTextBackup( self, ... );
  end

  local function Insert ( self, ... )
    CodeCache[ self ] = nil;
    return InsertBackup( self, ... );
  end

  --- @return Cursor position within un-colored text.
  local function GetCursorPosition ( self, ... )
    local _, Cursor = lib.StripColors( GetTextBackup( self ),
      GetCursorPositionBackup( self, ... ) );
    return Cursor;
  end

  --- Sets the cursor position relative to un-colored text.
  local function SetCursorPosition ( self, Cursor, ... )
    local _, Cursor = lib.FormatCode( GetCodeCached( self ),
      nil, self.faiap_colorTable, Cursor );
    return SetCursorPositionBackup( self, Cursor, ... );
  end

  --- Highlights a substring relative to un-colored text.
  local function HighlightText ( self, Start, End, ... )
    if ( Start ~= End and ( Start or End ) ) then
      local Code, _ = GetCodeCached( self );
      if ( Start ) then
        _, Start = lib.FormatCode( GetCodeCached( self ),
          nil, self.faiap_colorTable, Start );
      end
      if ( End ) then
        _, End = lib.FormatCode( GetCodeCached( self ),
          nil, self.faiap_colorTable, End );
      end
    end
    return HighlightTextBackup( self, Start, End, ... );
  end

  --- Updates the code a moment after the user quits typing.
  local function UpdaterOnFinished ( Updater )
    return lib.Update( Updater.EditBox );
  end

  local function HookHandler ( self, Handler, Script )
    self[ "faiap_"..Handler ] = self:GetScript( Handler );
    self:SetScript( Handler, Script );
  end

  --- Enables syntax highlighting or auto-indentation on this edit box.
  -- Can be run again to change the TabWidth or ColorTable.
  -- @param TabWidth  Tab width to indent code by, or nil for no indentation.
  -- @param ColorTable  Table of tokens and token types to color codes used for
  --   syntax highlighting, or nil for no syntax highlighting.
  -- @param SuppressIndent  Don't immediately re-indent text, even with TabWidth enabled.
  -- @return True if enabled and formatted.
  function lib:Enable ( TabWidth, ColorTable, SuppressIndent )
    if ( not SetTextBackup ) then
      GetTextBackup, SetTextBackup = self.GetText, self.SetText;
      InsertBackup = self.Insert;
      GetCursorPositionBackup = self.GetCursorPosition;
      SetCursorPositionBackup = self.SetCursorPosition;
      HighlightTextBackup = self.HighlightText;
    end
    if ( not ( TabWidth or ColorTable ) ) then
      return lib.Disable( self );
    end

    if ( not Enabled[ self ] ) then
      self.faiap_maxBytes = self:GetMaxBytes();
      self.faiap_countInvisible = self:IsCountInvisibleLetters();
      self:SetMaxBytes( 0 );
      self:SetCountInvisibleLetters( false );
      self.GetText, self.SetText = GetText, SetText;
      self.Insert = Insert;
      self.GetCursorPosition = GetCursorPosition;
      self.SetCursorPosition = SetCursorPosition;
      self.HighlightText = HighlightText;

      if ( Enabled[ self ] == nil ) then -- Never hooked before
        -- Note: Animation must not be parented to EditBox, or else lots of
        -- text will cause huge framerate drops after Updater:Play().
        local Updater = CreateFrame( "Frame", nil, self ):CreateAnimationGroup();
        Updaters[ self ], Updater.EditBox = Updater, self;
        Updater:CreateAnimation( "Animation" ):SetDuration( UPDATE_INTERVAL );
        Updater:SetScript( "OnFinished", UpdaterOnFinished );
        HookHandler( self, "OnTextChanged", OnTextChanged );
        HookHandler( self, "OnTabPressed", OnTabPressed );
      end
      Enabled[ self ] = true;
    end
    self.faiap_tabWidth, self.faiap_colorTable = TabWidth, ColorTable;
    ColoredCache[ self ] = nil; -- Force update with new tab width/colors

    return lib.Update( self, not SuppressIndent );
  end
end

-- Token types
lib.Tokens = {}; --- Token names to TokenTypeIDs, used to define custom ColorTables.
local NewToken;
do
  local Count = 0;
  --- @return A new token ID assigned to Name.
  function NewToken ( Name )
    Count = Count + 1;
    lib.Tokens[ Name ] = Count;
    return Count;
  end
end

local TK_UNKNOWN = NewToken( "UNKNOWN" );
local TK_IDENTIFIER = NewToken( "IDENTIFIER" );
local TK_KEYWORD = NewToken( "KEYWORD" ); -- Reserved words

local TK_ADD = NewToken( "ADD" );
local TK_ASSIGNMENT = NewToken( "ASSIGNMENT" );
local TK_COLON = NewToken( "COLON" );
local TK_COMMA = NewToken( "COMMA" );
local TK_COMMENT_LONG = NewToken( "COMMENT_LONG" );
local TK_COMMENT_SHORT = NewToken( "COMMENT_SHORT" );
local TK_CONCAT = NewToken( "CONCAT" );
local TK_DIVIDE = NewToken( "DIVIDE" );
local TK_EQUALITY = NewToken( "EQUALITY" );
local TK_GT = NewToken( "GT" );
local TK_GTE = NewToken( "GTE" );
local TK_LEFTBRACKET = NewToken( "LEFTBRACKET" );
local TK_LEFTCURLY = NewToken( "LEFTCURLY" );
local TK_LEFTPAREN = NewToken( "LEFTPAREN" );
local TK_LINEBREAK = NewToken( "LINEBREAK" );
local TK_LT = NewToken( "LT" );
local TK_LTE = NewToken( "LTE" );
local TK_MODULUS = NewToken( "MODULUS" );
local TK_MULTIPLY = NewToken( "MULTIPLY" );
local TK_NOTEQUAL = NewToken( "NOTEQUAL" );
local TK_NUMBER = NewToken( "NUMBER" );
local TK_PERIOD = NewToken( "PERIOD" );
local TK_POWER = NewToken( "POWER" );
local TK_RIGHTBRACKET = NewToken( "RIGHTBRACKET" );
local TK_RIGHTCURLY = NewToken( "RIGHTCURLY" );
local TK_RIGHTPAREN = NewToken( "RIGHTPAREN" );
local TK_SEMICOLON = NewToken( "SEMICOLON" );
local TK_SIZE = NewToken( "SIZE" );
local TK_STRING = NewToken( "STRING" );
local TK_STRING_LONG = NewToken( "STRING_LONG" ); -- [=[...]=]
local TK_SUBTRACT = NewToken( "SUBTRACT" );
local TK_VARARG = NewToken( "VARARG" );
local TK_WHITESPACE = NewToken( "WHITESPACE" );

local strbyte = string.byte;
local BYTE_0 = strbyte( "0" );
local BYTE_9 = strbyte( "9" );
local BYTE_ASTERISK = strbyte( "*" );
local BYTE_BACKSLASH = strbyte( "\\" );
local BYTE_CIRCUMFLEX = strbyte( "^" );
local BYTE_COLON = strbyte( ":" );
local BYTE_COMMA = strbyte( "," );
local BYTE_CR = strbyte( "\r" );
local BYTE_DOUBLE_QUOTE = strbyte( "\"" );
local BYTE_E = strbyte( "E" );
local BYTE_e = strbyte( "e" );
local BYTE_EQUALS = strbyte( "=" );
local BYTE_GREATERTHAN = strbyte( ">" );
local BYTE_HASH = strbyte( "#" );
local BYTE_LEFTBRACKET = strbyte( "[" );
local BYTE_LEFTCURLY = strbyte( "{" );
local BYTE_LEFTPAREN = strbyte( "(" );
local BYTE_LESSTHAN = strbyte( "<" );
local BYTE_LF = strbyte( "\n" );
local BYTE_MINUS = strbyte( "-" );
local BYTE_PERCENT = strbyte( "%" );
local BYTE_PERIOD = strbyte( "." );
local BYTE_PLUS = strbyte( "+" );
local BYTE_RIGHTBRACKET = strbyte( "]" );
local BYTE_RIGHTCURLY = strbyte( "}" );
local BYTE_RIGHTPAREN = strbyte( ")" );
local BYTE_SEMICOLON = strbyte( ";" );
local BYTE_SINGLE_QUOTE = strbyte( "'" );
local BYTE_SLASH = strbyte( "/" );
local BYTE_SPACE = strbyte( " " );
local BYTE_TAB = strbyte( "\t" );
local BYTE_TILDE = strbyte( "~" );

local Linebreaks = {
  [ BYTE_CR ] = true;
  [ BYTE_LF ] = true;
}

local Whitespace = {
  [ BYTE_SPACE ] = true;
  [ BYTE_TAB ] = true;
}

--- Mapping of bytes to the only tokens they can represent, or true if indeterminate
local TokenBytes = {
  [ BYTE_ASTERISK ] = TK_MULTIPLY;
  [ BYTE_CIRCUMFLEX ] = TK_POWER;
  [ BYTE_COLON ] = TK_COLON;
  [ BYTE_COMMA ] = TK_COMMA;
  [ BYTE_DOUBLE_QUOTE ] = true;
  [ BYTE_EQUALS ] = true;
  [ BYTE_GREATERTHAN ] = true;
  [ BYTE_HASH ] = TK_SIZE;
  [ BYTE_LEFTBRACKET ] = true;
  [ BYTE_LEFTCURLY ] = TK_LEFTCURLY;
  [ BYTE_LEFTPAREN ] = TK_LEFTPAREN;
  [ BYTE_LESSTHAN ] = true;
  [ BYTE_MINUS ] = true;
  [ BYTE_PERCENT ] = TK_MODULUS;
  [ BYTE_PERIOD ] = true;
  [ BYTE_PLUS ] = TK_ADD;
  [ BYTE_RIGHTBRACKET ] = TK_RIGHTBRACKET;
  [ BYTE_RIGHTCURLY ] = TK_RIGHTCURLY;
  [ BYTE_RIGHTPAREN ] = TK_RIGHTPAREN;
  [ BYTE_SEMICOLON ] = TK_SEMICOLON;
  [ BYTE_SINGLE_QUOTE ] = true;
  [ BYTE_SLASH ] = TK_DIVIDE;
  [ BYTE_TILDE ] = true;
}

local strfind = string.find;
--- Reads the next Lua identifier from its beginning.
local function NextIdentifier ( Text, Pos )
  local _, End = strfind( Text, "^[_%a][_%w]*", Pos );
  if ( End ) then
    return TK_IDENTIFIER, End + 1;
  else
    return TK_UNKNOWN, Pos + 1;
  end
end

--- Reads all following decimal digits.
local function NextNumberDecPart ( Text, Pos )
  local _, End = strfind( Text, "^%d+", Pos );
  return TK_NUMBER, End and End + 1 or Pos;
end

--- Reads the next scientific e notation exponent beginning after the 'e'.
local function NextNumberExponentPart ( Text, Pos )
  local Byte = strbyte( Text, Pos );
  if ( not Byte ) then
    return TK_NUMBER, Pos;
  end
  if ( Byte == BYTE_MINUS ) then
    -- Handle this case: "1.2e-- comment" with "1.2e" as a number
    if ( strbyte( Text, Pos + 1 ) == BYTE_MINUS ) then
      return TK_NUMBER, Pos;
    end
    Pos = Pos + 1;
  end
  return NextNumberDecPart( Text, Pos );
end

--- Reads the fractional part of a number beginning after the decimal.
local function NextNumberFractionPart ( Text, Pos )
  local _, Pos = NextNumberDecPart( Text, Pos );
  if ( strfind( Text, "^[Ee]", Pos ) ) then
    return NextNumberExponentPart( Text, Pos + 1 );
  else
    return TK_NUMBER, Pos;
  end
end

--- Reads all following hex digits.
local function NextNumberHexPart ( Text, Pos )
  local _, End = strfind( Text, "^%x+", Pos );
  return TK_NUMBER, End and End + 1 or Pos;
end

--- Reads the next number from its beginning.
local function NextNumber ( Text, Pos )
  if ( strfind( Text, "^0[Xx]", Pos ) ) then
    return NextNumberHexPart( Text, Pos + 2 );
  end
  local _, Pos = NextNumberDecPart( Text, Pos );
  local Byte = strbyte( Text, Pos );
  if ( Byte == BYTE_PERIOD ) then
    return NextNumberFractionPart( Text, Pos + 1 );
  elseif ( Byte == BYTE_E or Byte == BYTE_e ) then
    return NextNumberExponentPart( Text, Pos + 1 );
  else
    return TK_NUMBER, Pos;
  end
end

--- @return PosNext, EqualsCount if next token is a long string.
local function NextLongStringStart ( Text, Pos )
  local Start, End = strfind( Text, "^%[=*%[", Pos );
  if ( End ) then
    return End + 1, End - Start - 1;
  end
end

--- Reads the next long string beginning after its opening brackets.
local function NextLongString ( Text, Pos, EqualsCount )
  local _, End = strfind( Text, "]"..( "=" ):rep( EqualsCount ).."]", Pos, true );
  return TK_STRING_LONG, ( End or #Text ) + 1;
end

--- Reads the next short or long comment beginning after its dashes.
local function NextComment ( Text, Pos )
  local PosNext, EqualsCount = NextLongStringStart( Text, Pos );
  if ( PosNext ) then
    local _, PosNext = NextLongString( Text, PosNext, EqualsCount );
    return TK_COMMENT_LONG, PosNext;
  end
  -- Short comment; ends at linebreak
  local _, End = strfind( Text, "[^\r\n]*", Pos );
  return TK_COMMENT_SHORT, End + 1;
end

local strchar = string.char;
--- Reads the next single/double quoted string beginning at its opening quote.
-- Note: Strings with unescaped newlines aren't properly terminated.
local function NextString ( Text, Pos, QuoteByte )
  local Pattern, Start = [[\*]]..strchar( QuoteByte );
  while ( Pos ) do
    Start, Pos = strfind( Text, Pattern, Pos + 1 );
    if ( Pos and ( Pos - Start ) % 2 == 0 ) then -- Not escaped
      return TK_STRING, Pos + 1;
    end
  end
  return TK_STRING, #Text + 1;
end

--- @return Token type or nil if end of string, position of char after token.
local function NextToken ( Text, Pos )
  local Byte = strbyte( Text, Pos );
  if ( not Byte ) then
    return;
  end

  if ( Linebreaks[ Byte ] ) then
    return TK_LINEBREAK, Pos + 1;
  end

  if ( Whitespace[ Byte ] ) then
    local _, End = strfind( Text, "^[ \t]*", Pos + 1 );
    return TK_WHITESPACE, End + 1;
  end

  local Token = TokenBytes[ Byte ];
  if ( Token ) then
    if ( Token ~= true ) then -- Byte can only represent this token
      return Token, Pos + 1;
    end

    if ( Byte == BYTE_SINGLE_QUOTE or Byte == BYTE_DOUBLE_QUOTE ) then
      return NextString( Text, Pos, Byte );

    elseif ( Byte == BYTE_LEFTBRACKET ) then
      local PosNext, EqualsCount = NextLongStringStart( Text, Pos );
      if ( PosNext ) then
        return NextLongString( Text, PosNext, EqualsCount );
      else
        return TK_LEFTBRACKET, Pos + 1;
      end
    end

    if ( Byte == BYTE_MINUS ) then
      if ( strbyte( Text, Pos + 1 ) == BYTE_MINUS ) then
        return NextComment( Text, Pos + 2 );
      end
      return TK_SUBTRACT, Pos + 1;

    elseif ( Byte == BYTE_EQUALS ) then
      if ( strbyte( Text, Pos + 1 ) == BYTE_EQUALS ) then
        return TK_EQUALITY, Pos + 2;
      end
      return TK_ASSIGNMENT, Pos + 1;

    elseif ( Byte == BYTE_PERIOD ) then
      local Byte2 = strbyte( Text, Pos + 1 );
      if ( Byte2 == BYTE_PERIOD ) then
        if ( strbyte( Text, Pos + 2 ) == BYTE_PERIOD ) then
          return TK_VARARG, Pos + 3;
        end
        return TK_CONCAT, Pos + 2;
      elseif ( Byte2 and Byte2 >= BYTE_0 and Byte2 <= BYTE_9 ) then
        return NextNumberFractionPart( Text, Pos + 2 );
      end
      return TK_PERIOD, Pos + 1;

    elseif ( Byte == BYTE_LESSTHAN ) then
      if ( strbyte( Text, Pos + 1 ) == BYTE_EQUALS ) then
        return TK_LTE, Pos + 2;
      end
      return TK_LT, Pos + 1;

    elseif ( Byte == BYTE_GREATERTHAN ) then
      if ( strbyte( Text, Pos + 1 ) == BYTE_EQUALS ) then
        return TK_GTE, Pos + 2;
      end
      return TK_GT, Pos + 1;

    elseif ( Byte == BYTE_TILDE
      and strbyte( Text, Pos + 1 ) == BYTE_EQUALS
      ) then
      return TK_NOTEQUAL, Pos + 2;
    end
  elseif ( Byte >= BYTE_0 and Byte <= BYTE_9 ) then
    return NextNumber( Text, Pos );
  else
    return NextIdentifier( Text, Pos );
  end
  return TK_UNKNOWN, Pos + 1;
end


local Keywords = {
  [ "nil" ] = true;
  [ "true" ] = true;
  [ "false" ] = true;
  [ "local" ] = true;
  [ "and" ] = true;
  [ "or" ] = true;
  [ "not" ] = true;
  [ "while" ] = true;
  [ "for" ] = true;
  [ "in" ] = true;
  [ "do" ] = true;
  [ "repeat" ] = true;
  [ "break" ] = true;
  [ "until" ] = true;
  [ "if" ] = true;
  [ "elseif" ] = true;
  [ "then" ] = true;
  [ "else" ] = true;
  [ "function" ] = true;
  [ "return" ] = true;
  [ "end" ] = true;
}

local IndentOpen = { 0, 1 }
local IndentClose = { -1, 0 }
local IndentBoth = { -1, 1 }

local Indents = {
  [ "do" ] = IndentOpen;
  [ "then" ] = IndentOpen;
  [ "repeat" ] = IndentOpen;
  [ "function" ] = IndentOpen;
  [ TK_LEFTPAREN ] = IndentOpen;
  [ TK_LEFTBRACKET ] = IndentOpen;
  [ TK_LEFTCURLY ] = IndentOpen;

  [ "until" ] = IndentClose;
  [ "elseif" ] = IndentClose;
  [ "end" ] = IndentClose;
  [ TK_RIGHTPAREN ] = IndentClose;
  [ TK_RIGHTBRACKET ] = IndentClose;
  [ TK_RIGHTCURLY ] = IndentClose;

  [ "else" ] = IndentBoth;
}

local strrep, strsub = string.rep, string.sub
local tinsert = table.insert
local TERMINATOR = "|r"
local Buffer = {}

--- Syntax highlights and indents a string of Lua code.
-- @param CursorOld  Optional cursor position to keep track of.
-- @see lib.Enable
-- @return Formatted text, and an updated cursor position if requested.
function lib:FormatCode ( TabWidth, ColorTable, CursorOld )
  if ( not ( TabWidth or ColorTable ) ) then
    return self, CursorOld;
  end

  wipe( Buffer );
  local BufferLen = 0;
  local Cursor, CursorIndented;
  local ColorLast;

  local LineLast, PassedIndent = 0, false;
  local Depth, DepthNext = 0, 0;

  local TokenType, PosNext, Pos = TK_UNKNOWN, 1;
  while ( TokenType ) do
    Pos, TokenType, PosNext = PosNext, NextToken( self, PosNext );

    if ( TokenType
      and ( PassedIndent or not TabWidth or TokenType ~= TK_WHITESPACE )
      ) then
      PassedIndent = true; -- Passed leading whitespace
      local Token = strsub( self, Pos, PosNext - 1 );

      local ColorCode;
      if ( ColorTable ) then -- Add coloring
        local Color = ColorTable[ Keywords[ Token ] and TK_KEYWORD or Token ]
          or ColorTable[ TokenType ];
      ColorCode = ( ColorLast and not Color and TERMINATOR ) -- End color
        or ( Color ~= ColorLast and Color ); -- Change color
      if ( ColorCode ) then
        Buffer[ #Buffer + 1 ], BufferLen = ColorCode, BufferLen + #ColorCode;
        end
        ColorLast = Color;
      end

      Buffer[ #Buffer + 1 ], BufferLen = Token, BufferLen + #Token;

      if ( CursorOld and not Cursor
        and CursorOld < PosNext - 1 -- Before end of token
        ) then
        local Offset = PosNext - CursorOld - 1; -- Distance to end of token
        if ( Offset > #Token ) then -- Cursor was in a previous skipped token
          Offset = #Token; -- Move to start of current token
        end
        -- Note: Cursor must not be directly inside of color codes, i.e.
        -- |cffxxxxxx_ or _|r, else the cursor can interact with them directly.
        if ( ColorCode and ColorLast -- Added color start code before token
          and Offset == #Token -- Cursor at start of token
          ) then
          Offset = Offset + #ColorCode; -- Move to before color code
        end
        Cursor = BufferLen - Offset;
      end

      local Indent = TabWidth and (
        ( TokenType == TK_IDENTIFIER and Indents[ Token ] )
        or Indents[ TokenType ] );
      if ( Indent ) then -- Apply token indent-modifier
        if ( DepthNext > 0 ) then
          DepthNext = DepthNext + Indent[ 1 ];
      else
        Depth = Depth + Indent[ 1 ];
      end
      DepthNext = DepthNext + Indent[ 2 ];
      end
    end

    if ( TabWidth and ( not TokenType or TokenType == TK_LINEBREAK ) ) then
      -- Indent previous line
      local Indent = strrep( " ", Depth * TabWidth );
      BufferLen = BufferLen + #Indent;
      tinsert( Buffer, LineLast + 1, Indent );

      if ( Cursor and not CursorIndented ) then
        Cursor = Cursor + #Indent;
        if ( CursorOld < Pos ) then -- Cursor on this line
          CursorIndented = true;
        end -- Else cursor is on next line and must be indented again
      end

      LineLast, PassedIndent = #Buffer, false;
      Depth, DepthNext = Depth + DepthNext, 0;
      if ( Depth < 0 ) then
        Depth = 0;
      end
    end
  end
  return table.concat( Buffer ), Cursor or BufferLen;
end


local COLOR_NUMBERS = '|cFFFFD100'
local COLOR_TRUE = '|cFF00FF00'
local COLOR_FALSE = '|cFFFF0000'
local COLOR_STRING = '|cFF008888'
local COLOR_DEFAULT = '|cFFFFFFFF'
local COLOR_NORMAL = '|r'


function ns.formatValue( value )

  if value == nil then value = 'nil' end

  if type( value ) == 'number' then
    -- Check for decimal places.
    if select(2, modf( value )) ~= 0 then
      return COLOR_NUMBERS .. round( value, 2 ) .. COLOR_NORMAL
    else
      return COLOR_NUMBERS .. value .. COLOR_NORMAL
    end

  elseif type( value ) == 'boolean' then
    if value then
      return COLOR_TRUE .. tostring( value ) .. COLOR_NORMAL
    else
      return COLOR_FALSE .. tostring( value ) .. COLOR_NORMAL
    end

  elseif type( value ) == 'string' then
    return COLOR_STRING .. value .. COLOR_NORMAL

  end

  return COLOR_DEFAULT .. tostring( value ) .. COLOR_NORMAL

end
