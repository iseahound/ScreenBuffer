#include ScreenBuffer.ahk

sb1 := ScreenBuffer.GDI()
sb2 := ScreenBuffer.DIRECTX9()
sb3 := ScreenBuffer.DIRECTX11()

MsgBox "Please watch a 60fps video or play a game during testing.`nPress OK to begin."
Sleep 2000 ; Minimize variance on start.

; Number of Frames per test
f := 60


; ------------------------ |
; Screen Capture Framerate |
; ------------------------ |

DllCall("QueryPerformanceFrequency", "int64*", &frequency:=0)
DllCall("QueryPerformanceCounter", "int64*", &start:=0)
loop f
   sb1()
DllCall("QueryPerformanceCounter", "int64*", &end:=0)
a := f / ((end - start) / frequency)

DllCall("QueryPerformanceCounter", "int64*", &start:=0)
loop f
   sb2()
DllCall("QueryPerformanceCounter", "int64*", &end:=0)
b := f / ((end - start) / frequency)

DllCall("QueryPerformanceCounter", "int64*", &start:=0)
loop f
   sb3()
DllCall("QueryPerformanceCounter", "int64*", &end:=0)
c := f / ((end - start) / frequency)

DllCall("QueryPerformanceCounter", "int64*", &start:=0)
loop f
   sb3(0)
DllCall("QueryPerformanceCounter", "int64*", &end:=0)
d := f / ((end - start) / frequency)

MsgBox "GDI:`t`t"    Round(a, 2)   " fps"
   . "`nDX9:`t`t"    Round(b, 2)   " fps"
   . "`nDX11:`t`t"   Round(c, 2)   " fps"
   . "`nDX11 (uncapped):`t"   Round(d, 2)   " fps"
   . "`n`nTotal number of frames per test: " f
   , "(Test 1 of 3) Screen Capture Framerate"


; -------------------------------- |
; Save To Bitmap Capture Framerate |
; -------------------------------- |

DllCall("QueryPerformanceFrequency", "int64*", &frequency:=0)
DllCall("QueryPerformanceCounter", "int64*", &start:=0)
loop f
   sb1().SaveRaw("image.bmp")
DllCall("QueryPerformanceCounter", "int64*", &end:=0)
a := f / ((end - start) / frequency)

DllCall("QueryPerformanceCounter", "int64*", &start:=0)
loop f
   sb2().SaveRaw("image.bmp")
DllCall("QueryPerformanceCounter", "int64*", &end:=0)
b := f / ((end - start) / frequency)

DllCall("QueryPerformanceCounter", "int64*", &start:=0)
loop f
   sb3().SaveRaw("image.bmp")
DllCall("QueryPerformanceCounter", "int64*", &end:=0)
c := f / ((end - start) / frequency)

DllCall("QueryPerformanceCounter", "int64*", &start:=0)
loop f
   sb3(0).SaveRaw("image.bmp")
DllCall("QueryPerformanceCounter", "int64*", &end:=0)
d := f / ((end - start) / frequency)

MsgBox "GDI:`t`t"    Round(a, 2)   " fps"
   . "`nDX9:`t`t"    Round(b, 2)   " fps"
   . "`nDX11:`t`t"   Round(c, 2)   " fps"
   . "`nDX11 (uncapped):`t"   Round(d, 2)   " fps"
   . "`n`nTotal number of frames per test: " f
   , "(Test 2 of 3) Save To Bitmap Capture Framerate"


; ---------------------- |
; JPEG Capture Framerate |
; ---------------------- |

DllCall("QueryPerformanceFrequency", "int64*", &frequency:=0)
DllCall("QueryPerformanceCounter", "int64*", &start:=0)
loop f
   sb1().Save("image.jpg")
DllCall("QueryPerformanceCounter", "int64*", &end:=0)
a := f / ((end - start) / frequency)

DllCall("QueryPerformanceCounter", "int64*", &start:=0)
loop f
   sb2().Save("image.jpg")
DllCall("QueryPerformanceCounter", "int64*", &end:=0)
b := f / ((end - start) / frequency)

DllCall("QueryPerformanceCounter", "int64*", &start:=0)
loop f
   sb3().Save("image.jpg")
DllCall("QueryPerformanceCounter", "int64*", &end:=0)
c := f / ((end - start) / frequency)

DllCall("QueryPerformanceCounter", "int64*", &start:=0)
loop f
   sb3(0).Save("image.jpg")
DllCall("QueryPerformanceCounter", "int64*", &end:=0)
d := f / ((end - start) / frequency)

MsgBox "GDI:`t`t"    Round(a, 2)   " fps"
   . "`nDX9:`t`t"    Round(b, 2)   " fps"
   . "`nDX11:`t`t"   Round(c, 2)   " fps"
   . "`nDX11 (uncapped):`t"   Round(d, 2)   " fps"
   . "`n`nTotal number of frames per test: " f
   , "(Test 3 of 3) JPEG Capture Framerate"