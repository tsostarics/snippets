SetTitleMatchMode, RegEx
#IfWinActive TextGrid
$Numpad1::
    Send, {Ctrl down},.2{Ctrl up}1
    return

$Numpad2::
    Send, {Ctrl down},.2{Ctrl up}2
    return
    
$Numpad3::
    Send, {Ctrl down},.2{Ctrl up}3
    return

$Numpad5::
    send, {Tab}
    return

$Numpad0::
    Send, {Ctrl down}a{Ctrl up}
    return

$NumpadDot::
    Send, {Ctrl down}n{Ctrl up}
    return

$NumpadEnter::
    Send, {Ctrl down}s{Ctrl up}{Enter}{Left}{Enter}
    return

$NumpadAdd::
    Send, {Ctrl down}i{Ctrl up}
    return

$NumpadSub::
    Send, {Ctrl down}o{Ctrl up}
    return

$NumpadDiv::
    Send, {PgDn}
    return

$NumpadMult::
    Send, {PgUp}
    return

$NumLock::
    Send, {BackSpace 3}
    Send, !{BackSpace}
    Send, !{Right}
    Send, !{BackSpace}
    return

$Numpad7::
    Send, {BackSpace}1
    return

$Numpad8::
    Send, {BackSpace}2
    return

$Numpad9::
    Send, {BackSpace}3
    return