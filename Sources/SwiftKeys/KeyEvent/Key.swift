//===----------------------------------------------------------------------===//
//
// Key.swift
//
// Created: 2022. Author: Jordan Baird.
//
//===----------------------------------------------------------------------===//

import Carbon.HIToolbox

extension KeyEvent {
  /// Constants that represent the various keys available on a keyboard.
  public enum Key: CaseIterable {
    
    // MARK: - ANSI
    
    /// The ANSI A key.
    case a
    /// The ANSI B key.
    case b
    /// The ANSI C key.
    case c
    /// The ANSI D key.
    case d
    /// The ANSI E key.
    case e
    /// The ANSI F key.
    case f
    /// The ANSI G key.
    case g
    /// The ANSI H key.
    case h
    /// The ANSI I key.
    case i
    /// The ANSI J key.
    case j
    /// The ANSI K key.
    case k
    /// The ANSI L key.
    case l
    /// The ANSI M key.
    case m
    /// The ANSI N key.
    case n
    /// The ANSI O key.
    case o
    /// The ANSI P key.
    case p
    /// The ANSI Q key.
    case q
    /// The ANSI R key.
    case r
    /// The ANSI S key.
    case s
    /// The ANSI T key.
    case t
    /// The ANSI U key.
    case u
    /// The ANSI V key.
    case v
    /// The ANSI W key.
    case w
    /// The ANSI X key.
    case x
    /// The ANSI Y key.
    case y
    /// The ANSI Z key.
    case z
    
    /// The ANSI 0 key.
    case zero
    /// The ANSI 1 key.
    case one
    /// The ANSI 2 key.
    case two
    /// The ANSI 3 key.
    case three
    /// The ANSI 4 key.
    case four
    /// The ANSI 5 key.
    case five
    /// The ANSI 6 key.
    case six
    /// The ANSI 7 key.
    case seven
    /// The ANSI 8 key.
    case eight
    /// The ANSI 9 key.
    case nine
    
    /// The ANSI "-" key.
    case minus
    /// The ANSI "=" key.
    case equals
    /// The ANSI "[" key.
    case leftBracket
    /// The ANSI "]" key.
    case rightBracket
    /// The ANSI "\\" key.
    case backslash
    /// The ANSI ";" key.
    case semicolon
    /// The ANSI "'" key.
    case quote
    /// The ANSI "," key.
    case comma
    /// The ANSI "." key.
    case period
    /// The ANSI "/" key.
    case slash
    /// The ANSI "`" key.
    case grave
    
    /// The ANSI keypad Decimal key.
    case keypadDecimal
    /// The ANSI keypad Multiply key.
    case keypadMultiply
    /// The ANSI keypad Plus key.
    case keypadPlus
    /// The ANSI keypad Clear key.
    case keypadClear
    /// The ANSI keypad Divide key.
    case keypadDivide
    /// The ANSI keypad Enter key.
    case keypadEnter
    /// The ANSI keypad Minus key.
    case keypadMinus
    /// The ANSI keypad Equals key.
    case keypadEquals
    /// The ANSI keypad 0 key.
    case keypad0
    /// The ANSI keypad 1 key.
    case keypad1
    /// The ANSI keypad 2 key.
    case keypad2
    /// The ANSI keypad 3 key.
    case keypad3
    /// The ANSI keypad 4 key.
    case keypad4
    /// The ANSI keypad 5 key.
    case keypad5
    /// The ANSI keypad 6 key.
    case keypad6
    /// The ANSI keypad 7 key.
    case keypad7
    /// The ANSI keypad 8 key.
    case keypad8
    /// The ANSI keypad 9 key.
    case keypad9
    
    // MARK: - Layout-independent
    
    /// The layout-independent Return key.
    case `return`
    /// The layout-independent Tab key.
    case tab
    /// The layout-independent Space key.
    case space
    /// The layout-independent Delete key.
    case delete
    /// The layout-independent Forward Felete key.
    case forwardDelete
    /// The layout-independent Escape key.
    case escape
    /// The layout-independent Volume Up key.
    case volumeUp
    /// The layout-independent Volume Down key.
    case volumeDown
    /// The layout-independent Mute key.
    case mute
    /// The layout-independent Home key.
    case home
    /// The layout-independent End key.
    case end
    /// The layout-independent Page Up key.
    case pageUp
    /// The layout-independent Page Down key.
    case pageDown
    
    /// The layout-independent Left Arrow key.
    case leftArrow
    /// The layout-independent Right Arrow key.
    case rightArrow
    /// The layout-independent Down Arrow key.
    case downArrow
    /// The layout-independent Up Arrow key.
    case upArrow
    
    /// The layout-independent F1 key.
    case f1
    /// The layout-independent F2 key.
    case f2
    /// The layout-independent F3 key.
    case f3
    /// The layout-independent F4 key.
    case f4
    /// The layout-independent F5 key.
    case f5
    /// The layout-independent F6 key.
    case f6
    /// The layout-independent F7 key.
    case f7
    /// The layout-independent F8 key.
    case f8
    /// The layout-independent F9 key.
    case f9
    /// The layout-independent F10 key.
    case f10
    /// The layout-independent F11 key.
    case f11
    /// The layout-independent F12 key.
    case f12
    /// The layout-independent F13 key.
    case f13
    /// The layout-independent F14 key.
    case f14
    /// The layout-independent F15 key.
    case f15
    /// The layout-independent F16 key.
    case f16
    /// The layout-independent F17 key.
    case f17
    /// The layout-independent F18 key.
    case f18
    /// The layout-independent F19 key.
    case f19
    /// The layout-independent F20 key.
    case f20
    
    // MARK: - ISO
    
    /// The Section key that is available on ISO keyboards.
    case isoSection
    
    // MARK: - JIS
    
    /// The Yen key that is available on JIS keyboards.
    case jisYen
    /// The Underscore key that is available on JIS keyboards.
    case jisUnderscore
    /// The Comma key that is available on JIS keyboard keypads.
    case jisKeypadComma
    /// The Eisu key that is available on JIS keyboards.
    case jisEisu
    /// The Kana key that is available on JIS keyboards.
    case jisKana
    
    // MARK: - Properties
    
    /// The raw value of the key.
    public var rawValue: Int {
      switch self {
      case .a: return kVK_ANSI_A
      case .b: return kVK_ANSI_B
      case .c: return kVK_ANSI_C
      case .d: return kVK_ANSI_D
      case .e: return kVK_ANSI_E
      case .f: return kVK_ANSI_F
      case .g: return kVK_ANSI_G
      case .h: return kVK_ANSI_H
      case .i: return kVK_ANSI_I
      case .j: return kVK_ANSI_J
      case .k: return kVK_ANSI_K
      case .l: return kVK_ANSI_L
      case .m: return kVK_ANSI_M
      case .n: return kVK_ANSI_N
      case .o: return kVK_ANSI_O
      case .p: return kVK_ANSI_P
      case .q: return kVK_ANSI_Q
      case .r: return kVK_ANSI_R
      case .s: return kVK_ANSI_S
      case .t: return kVK_ANSI_T
      case .u: return kVK_ANSI_U
      case .v: return kVK_ANSI_V
      case .w: return kVK_ANSI_W
      case .x: return kVK_ANSI_X
      case .y: return kVK_ANSI_Y
      case .z: return kVK_ANSI_Z
      case .zero: return kVK_ANSI_0
      case .one: return kVK_ANSI_1
      case .two: return kVK_ANSI_2
      case .three: return kVK_ANSI_3
      case .four: return kVK_ANSI_4
      case .five: return kVK_ANSI_5
      case .six: return kVK_ANSI_6
      case .seven: return kVK_ANSI_7
      case .eight: return kVK_ANSI_8
      case .nine: return kVK_ANSI_9
      case .minus: return kVK_ANSI_Minus
      case .equals: return kVK_ANSI_Equal
      case .leftBracket: return kVK_ANSI_LeftBracket
      case .rightBracket: return kVK_ANSI_RightBracket
      case .backslash: return kVK_ANSI_Backslash
      case .semicolon: return kVK_ANSI_Semicolon
      case .quote: return kVK_ANSI_Quote
      case .comma: return kVK_ANSI_Comma
      case .period: return kVK_ANSI_Period
      case .slash: return kVK_ANSI_Slash
      case .grave: return kVK_ANSI_Grave
      case .keypadDecimal: return kVK_ANSI_KeypadDecimal
      case .keypadMultiply: return kVK_ANSI_KeypadMultiply
      case .keypadPlus: return kVK_ANSI_KeypadPlus
      case .keypadClear: return kVK_ANSI_KeypadClear
      case .keypadDivide: return kVK_ANSI_KeypadDivide
      case .keypadEnter: return kVK_ANSI_KeypadEnter
      case .keypadMinus: return kVK_ANSI_KeypadMinus
      case .keypadEquals: return kVK_ANSI_KeypadEquals
      case .keypad0: return kVK_ANSI_Keypad0
      case .keypad1: return kVK_ANSI_Keypad1
      case .keypad2: return kVK_ANSI_Keypad2
      case .keypad3: return kVK_ANSI_Keypad3
      case .keypad4: return kVK_ANSI_Keypad4
      case .keypad5: return kVK_ANSI_Keypad5
      case .keypad6: return kVK_ANSI_Keypad6
      case .keypad7: return kVK_ANSI_Keypad7
      case .keypad8: return kVK_ANSI_Keypad8
      case .keypad9: return kVK_ANSI_Keypad9
      case .return: return kVK_Return
      case .tab: return kVK_Tab
      case .space: return kVK_Space
      case .delete: return kVK_Delete
      case .forwardDelete: return kVK_ForwardDelete
      case .escape: return kVK_Escape
      case .volumeUp: return kVK_VolumeUp
      case .volumeDown: return kVK_VolumeDown
      case .mute: return kVK_Mute
      case .home: return kVK_Home
      case .end: return kVK_End
      case .pageUp: return kVK_PageUp
      case .pageDown: return kVK_PageDown
      case .leftArrow: return kVK_LeftArrow
      case .rightArrow: return kVK_RightArrow
      case .downArrow: return kVK_DownArrow
      case .upArrow: return kVK_UpArrow
      case .f1: return kVK_F1
      case .f2: return kVK_F2
      case .f3: return kVK_F3
      case .f4: return kVK_F4
      case .f5: return kVK_F5
      case .f6: return kVK_F6
      case .f7: return kVK_F7
      case .f8: return kVK_F8
      case .f9: return kVK_F9
      case .f10: return kVK_F10
      case .f11: return kVK_F11
      case .f12: return kVK_F12
      case .f13: return kVK_F13
      case .f14: return kVK_F14
      case .f15: return kVK_F15
      case .f16: return kVK_F16
      case .f17: return kVK_F17
      case .f18: return kVK_F18
      case .f19: return kVK_F19
      case .f20: return kVK_F20
      case .isoSection: return kVK_ISO_Section
      case .jisYen: return kVK_JIS_Yen
      case .jisUnderscore: return kVK_JIS_Underscore
      case .jisKeypadComma: return kVK_JIS_KeypadComma
      case .jisEisu: return kVK_JIS_Eisu
      case .jisKana: return kVK_JIS_Kana
      }
    }
    
    /// A string representation of the key.
    public var stringValue: String {
      switch self {
      case .a: return "a"
      case .b: return "b"
      case .c: return "c"
      case .d: return "d"
      case .e: return "e"
      case .f: return "f"
      case .g: return "g"
      case .h: return "h"
      case .i: return "i"
      case .j: return "j"
      case .k: return "k"
      case .l: return "l"
      case .m: return "m"
      case .n: return "n"
      case .o: return "o"
      case .p: return "p"
      case .q: return "q"
      case .r: return "r"
      case .s: return "s"
      case .t: return "t"
      case .u: return "u"
      case .v: return "v"
      case .w: return "w"
      case .x: return "x"
      case .y: return "y"
      case .z: return "z"
      case .zero: return "0"
      case .one: return "1"
      case .two: return "2"
      case .three: return "3"
      case .four: return "4"
      case .five: return "5"
      case .six: return "6"
      case .seven: return "7"
      case .eight: return "8"
      case .nine: return "9"
      case .minus: return "-"
      case .equals: return "="
      case .leftBracket: return "["
      case .rightBracket: return "]"
      case .backslash: return "\\"
      case .semicolon: return ";"
      case .quote: return "'"
      case .comma: return ","
      case .period: return "."
      case .slash: return "/"
      case .grave: return "`"
      case .keypadDecimal: return "."
      case .keypadMultiply: return "*"
      case .keypadPlus: return "+"
      case .keypadClear: return "⌧"
      case .keypadDivide: return "÷"
      case .keypadEnter: return "⌅"
      case .keypadMinus: return "-"
      case .keypadEquals: return "="
      case .keypad0: return "0"
      case .keypad1: return "1"
      case .keypad2: return "2"
      case .keypad3: return "3"
      case .keypad4: return "4"
      case .keypad5: return "5"
      case .keypad6: return "6"
      case .keypad7: return "7"
      case .keypad8: return "8"
      case .keypad9: return "9"
      case .return: return "⏎"
      case .tab: return "⇥"
      case .space: return "␣"
      case .delete: return "⌫"
      case .forwardDelete: return "⌦"
      case .escape: return "⎋"
      case .volumeUp: return "􏿮"
      case .volumeDown: return "􏿮"
      case .mute: return "􏿮"
      case .home: return "⇱"
      case .end: return "⇲"
      case .pageUp: return "⇞"
      case .pageDown: return "⇟"
      case .leftArrow: return "←"
      case .rightArrow: return "→"
      case .downArrow: return "↓"
      case .upArrow: return "↑"
      case .f1: return "F1"
      case .f2: return "F2"
      case .f3: return "F3"
      case .f4: return "F4"
      case .f5: return "F5"
      case .f6: return "F6"
      case .f7: return "F7"
      case .f8: return "F8"
      case .f9: return "F9"
      case .f10: return "F10"
      case .f11: return "F11"
      case .f12: return "F12"
      case .f13: return "F13"
      case .f14: return "F14"
      case .f15: return "F15"
      case .f16: return "F16"
      case .f17: return "F17"
      case .f18: return "F18"
      case .f19: return "F19"
      case .f20: return "F20"
      case .isoSection: return "§"
      case .jisYen: return "¥"
      case .jisUnderscore: return "_"
      case .jisKeypadComma: return ","
      case .jisEisu: return "英数"
      case .jisKana: return "かな"
      }
    }
    
    /// An unsigned version of the key's raw value.
    var unsigned: UInt32 {
      .init(rawValue)
    }
    
    // MARK: - Initializers
    
    /// Runs a check against all the possible values of `Key`, and if a
    /// case is found whose `rawValue` property matches the given integer,
    /// creates a value initialized to that case.
    init?(_ rawValue: Int) {
      let key = Self.allCases.first {
        $0.rawValue == rawValue
      }
      if let key = key {
        self = key
      } else {
        return nil
      }
    }
    
    /// Runs a check against all the possible values of `Key`, and if a
    /// case is found whose `stringValue` property matches the given string,
    /// creates a value initialized to that case.
    init?(_ string: String) {
      let key = Self.allCases.first {
        $0.stringValue.lowercased() == string.lowercased()
      }
      if let key = key {
        self = key
      } else {
        return nil
      }
    }
  }
}

extension KeyEvent.Key: Codable { }

extension KeyEvent.Key: Equatable { }

extension KeyEvent.Key: Hashable { }
