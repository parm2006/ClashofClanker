#Requires AutoHotkey v2.0
try {
    val := "123"
    res := val / 10
    FileAppend("res1=" res "`n", "*")
} catch as err {
    FileAppend("Error for division: " err.Message "`nType: " Type(err) "`n", "*")
}
try {
    val := "123"
    res := Round(val)
    FileAppend("res2=" res "`n", "*")
} catch as err {
    FileAppend("Error for Round: " err.Message "`nType: " Type(err) "`n", "*")
}
try {
    res := Round("abc")
    FileAppend("res3=" res "`n", "*")
} catch as err {
    FileAppend("Error for Round abc: " err.Message "`nType: " Type(err) "`n", "*")
}
try {
    res := Integer("abc")
} catch as err {
    FileAppend("Error for Integer abc: " err.Message "`nType: " Type(err) "`n", "*")
}
