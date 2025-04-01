setbatchlines -1

; Load GDI+
DllCall("LoadLibrary", "str", "gdiplus")
VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0) ; sizeof(GdiplusStartupInput) = 16, 24
NumPut(0x1, si, "uint")
DllCall("gdiplus\GdiplusStartup", "ptr*", pToken:=0, "ptr", &si, "ptr", 0)
extension := "png"
DllCall("gdiplus\GdipGetImageEncodersSize", "uint*", count:=0, "uint*", size:=0)
VarSetCapacity(ci, size)
DllCall("gdiplus\GdipGetImageEncoders", "uint", count, "uint", size, "ptr", &ci)
if !(count && size)
   throw Exception("Could not get a list of image codec encoders on this system.")
Loop % count
   EncoderExtensions := StrGet(NumGet(ci, (idx:=(48+7*A_PtrSize)*(A_Index-1))+32+3*A_PtrSize, "uptr"), "UTF-16")
      until InStr(EncoderExtensions, "*." extension)
if !(pCodec := &ci + idx)
   throw Exception("Could not find a matching encoder for the specified file format.")


IDXGIFactory := CreateDXGIFactory()
if !IDXGIFactory
{
   MsgBox, 16, Error, Create IDXGIFactory failed.
   ExitApp
}
loop
{
   IDXGIFactory_EnumAdapters(IDXGIFactory, A_Index-1, IDXGIAdapter)
   loop
   {
      hr := IDXGIAdapter_EnumOutputs(IDXGIAdapter, A_Index-1, IDXGIOutput)
      if (hr = "DXGI_ERROR_NOT_FOUND")
         break
      VarSetCapacity(DXGI_OUTPUT_DESC, 88+A_PtrSize, 0)
      IDXGIOutput_GetDesc(IDXGIOutput, &DXGI_OUTPUT_DESC)
      Width := NumGet(DXGI_OUTPUT_DESC, 72, "int")
      Height := NumGet(DXGI_OUTPUT_DESC, 76, "int")
      AttachedToDesktop := NumGet(DXGI_OUTPUT_DESC, 80, "int")
      if (AttachedToDesktop = 1)
         break 2         
   }
}
if (AttachedToDesktop != 1)
{
   MsgBox, 16, Error, No adapter attached to desktop
   ExitApp
}
D3D11CreateDevice(IDXGIAdapter, D3D_DRIVER_TYPE_UNKNOWN := 0, 0, 0, 0, 0, D3D11_SDK_VERSION := 7, d3d_device, 0, d3d_context)
IDXGIOutput1 := IDXGIOutput1_Query(IDXGIOutput)
IDXGIOutput1_DuplicateOutput(IDXGIOutput1, d3d_device, Duplication)
VarSetCapacity(DXGI_OUTDUPL_DESC, 36, 0)
IDXGIOutputDuplication_GetDesc(Duplication, &DXGI_OUTDUPL_DESC)
DesktopImageInSystemMemory := NumGet(DXGI_OUTDUPL_DESC, 32, "uint")
sleep 50   ; As I understand - need some sleep for successful connecting to IDXGIOutputDuplication interface

VarSetCapacity(D3D11_TEXTURE2D_DESC, 44, 0)
NumPut(width, D3D11_TEXTURE2D_DESC, 0, "uint")   ; Width
NumPut(height, D3D11_TEXTURE2D_DESC, 4, "uint")   ; Height
NumPut(1, D3D11_TEXTURE2D_DESC, 8, "uint")   ; MipLevels
NumPut(1, D3D11_TEXTURE2D_DESC, 12, "uint")   ; ArraySize
NumPut(DXGI_FORMAT_B8G8R8A8_UNORM := 87, D3D11_TEXTURE2D_DESC, 16, "uint")   ; Format
NumPut(1, D3D11_TEXTURE2D_DESC, 20, "uint")   ; SampleDescCount
NumPut(0, D3D11_TEXTURE2D_DESC, 24, "uint")   ; SampleDescQuality
NumPut(D3D11_USAGE_STAGING := 3, D3D11_TEXTURE2D_DESC, 28, "uint")   ; Usage
NumPut(0, D3D11_TEXTURE2D_DESC, 32, "uint")   ; BindFlags
NumPut(D3D11_CPU_ACCESS_READ := 0x20000, D3D11_TEXTURE2D_DESC, 36, "uint")   ; CPUAccessFlags
NumPut(0, D3D11_TEXTURE2D_DESC, 40, "uint")   ; MiscFlags
ID3D11Device_CreateTexture2D(d3d_device, &D3D11_TEXTURE2D_DESC, 0, staging_tex)

size2 := 4 * width * height
VarSetCapacity(bm, 54, 0)
StrPut("BM", &bm+0, "CP0") ;(identifier)
NumPut(54+size2, bm, 2, "uint") ;(file size)
NumPut(0, bm, 6, "uint") ;(reserved)
NumPut(54, bm, 10, "uint") ;(bitmap data offset)

;produce the header (BITMAPINFOHEADER struct):
         NumPut(       40, bm, 14,   "uint") ; Size
         NumPut(    width, bm, 18,   "uint") ; Width
         NumPut(  -height, bm, 22,    "int") ; Height - Negative so (0, 0) is top-left.
         NumPut(        1, bm, 26, "ushort") ; Planes
         NumPut(       32, bm, 28, "ushort") ; BitCount / BitsPerPixel

NumPut(0, bm, 30, "uint") ;biCompression
NumPut(size2, bm, 34, "uint") ;biSizeImage
NumPut(0, bm, 38, "int") ;biXPelsPerMeter
NumPut(0, bm, 42, "int") ;biYPelsPerMeter
NumPut(0, bm, 46, "uint") ;biClrUsed
NumPut(0, bm, 50, "uint") ;biClrImportant

VarSetCapacity(test, size2)

2::

f := 2400
DllCall("QueryPerformanceFrequency", "int64*", frequency:=0)
DllCall("QueryPerformanceCounter", "int64*", start:=0)
loop % f
{
   ; tooltip % A_Index
   VarSetCapacity(DXGI_OUTDUPL_FRAME_INFO, 48, 0)
   if (A_Index = 1)
   {
      loop
      {
         AcquireNextFrame := IDXGIOutputDuplication_AcquireNextFrame(Duplication, -1, &DXGI_OUTDUPL_FRAME_INFO, desktop_resource)
         LastPresentTime := NumGet(DXGI_OUTDUPL_FRAME_INFO, 40, "uint")
         if (LastPresentTime > 0)
            break
         ObjRelease(desktop_resource)
         IDXGIOutputDuplication_ReleaseFrame(duplication)
      }
   }
   else
   {
      AcquireNextFrame := IDXGIOutputDuplication_AcquireNextFrame(Duplication, 0, &DXGI_OUTDUPL_FRAME_INFO, desktop_resource)
      LastPresentTime := NumGet(DXGI_OUTDUPL_FRAME_INFO, 0, "int64")
   }
   if (AcquireNextFrame != "DXGI_ERROR_WAIT_TIMEOUT")
   {
      if (LastPresentTime > 0)
      {
         if (DesktopImageInSystemMemory = 1)
         {
            VarSetCapacity(DXGI_MAPPED_RECT, A_PtrSize*2, 0)
            IDXGIOutputDuplication_MapDesktopSurface(Duplication, &DXGI_MAPPED_RECT)
            pitch := NumGet(DXGI_MAPPED_RECT, 0, "int")
            pBits := NumGet(DXGI_MAPPED_RECT, A_PtrSize, "ptr")
         }
         else
         {
            tex := ID3D11Texture2D_Query(desktop_resource)
            ID3D11DeviceContext_CopyResource(d3d_context, staging_tex, tex)
            VarSetCapacity(D3D11_MAPPED_SUBRESOURCE, 8+A_PtrSize, 0)
            ID3D11DeviceContext_Map(d3d_context, staging_tex, 0, D3D11_MAP_READ := 1, 0, &D3D11_MAPPED_SUBRESOURCE)
            pBits := NumGet(D3D11_MAPPED_SUBRESOURCE, 0, "ptr")
            pitch := NumGet(D3D11_MAPPED_SUBRESOURCE, A_PtrSize, "uint")
         }
      }
   }


DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", width, "int", height, "int", pitch, "int", 0xE200B, "ptr", pBits, "ptr*", pBitmap:=0)
;   DllCall("gdiplus\GdipSaveImageToFile", "ptr", pBitmap, "wstr", A_Index ".bmp", "ptr", pCodec, "uint", 0)
DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)

; DllCall("RtlMoveMemory", "ptr", &test, "ptr", pBits+0, "uptr", size2)


; MsgBox % pBits+0

;NumGet(pBits+0, "uint")
;NumGet(pBits+4, "uint")
;NumGet(pBits+8, "uint")
;NumGet(pBits+12, "uint")
;NumGet(pBits+16, "uint")


vPath = image.bmp
oFile := FileOpen(vPath, "w")
oFile.RawWrite(bm, 54)
oFile.RawWrite(test, size2)
;oFile.RawWrite(pBits+0, size2)
oFile.Close()


   if (AcquireNextFrame != "DXGI_ERROR_WAIT_TIMEOUT")
   {
      if (LastPresentTime > 0)
      {
         if (DesktopImageInSystemMemory = 1)
            IDXGIOutputDuplication_UnMapDesktopSurface(Duplication)
         else
         {
            ID3D11DeviceContext_Unmap(d3d_context, staging_tex, 0)
            ObjRelease(tex)
         }
      }
      ObjRelease(desktop_resource)
      IDXGIOutputDuplication_ReleaseFrame(duplication)
   }
}
DllCall("QueryPerformanceCounter", "int64*", end:=0)
MsgBox % f / ((end - start) / frequency)
return


Release(staging_tex)
Release(d3d_device)
Release(d3d_context)
Release(duplication)
Release(IDXGIAdapter)
Release(IDXGIOutput)
Release(IDXGIOutput1)
Release(IDXGIFactory)
ExitApp




CreateDXGIFactory()
{
   if !DllCall("GetModuleHandle","str","DXGI")
      DllCall("LoadLibrary","str","DXGI")
   if !DllCall("GetModuleHandle","str","D3D11")
      DllCall("LoadLibrary","str","D3D11")
   GUID(riid, "{7b7166ec-21c7-44ae-b21a-c9ae321ae369}")
   hr := DllCall("DXGI\CreateDXGIFactory1", "ptr", &riid, "ptr*", ppFactory)
   if hr or ErrorLevel
      _Error(A_ThisFunc " error: " hr "`nErrorLevel: " ErrorLevel)
   return ppFactory
}

IDXGIFactory_EnumAdapters(this, Adapter, ByRef ppAdapter)
{
   hr := DllCall(NumGet(NumGet(this+0)+7*A_PtrSize), "ptr", this, "uint", Adapter, "ptr*", ppAdapter)
   if hr or ErrorLevel
      _Error(A_ThisFunc " error: " hr "`nErrorLevel: " ErrorLevel)
}

IDXGIAdapter_EnumOutputs(this, Output, ByRef ppOutput)
{
   hr := DllCall(NumGet(NumGet(this+0)+7*A_PtrSize), "ptr", this, "uint", Output, "ptr*", ppOutput)
   if hr or ErrorLevel
   {
      if (hr&=0xFFFFFFFF) = 0x887A0002   ; DXGI_ERROR_NOT_FOUND
         return "DXGI_ERROR_NOT_FOUND"
      _Error(A_ThisFunc " error: " hr "`nErrorLevel: " ErrorLevel)
   }
}

IDXGIAdapter_GetDesc(this, pDesc)
{
   hr := DllCall(NumGet(NumGet(this+0)+8*A_PtrSize), "ptr", this, "ptr", pDesc)
   if hr or ErrorLevel
      _Error(A_ThisFunc " error: " hr "`nErrorLevel: " ErrorLevel)
}

IDXGIOutput_GetDesc(this, pDesc)
{
   hr := DllCall(NumGet(NumGet(this+0)+7*A_PtrSize), "ptr", this, "ptr", pDesc)
   if hr or ErrorLevel
      _Error(A_ThisFunc " error: " hr "`nErrorLevel: " ErrorLevel)
}

IDXGIOutputDuplication_GetDesc(this, pDesc)
{
   DllCall(NumGet(NumGet(this+0)+7*A_PtrSize), "ptr", this, "ptr", pDesc)
   if ErrorLevel
      _Error(A_ThisFunc " error: " hr "`nErrorLevel: " ErrorLevel)
}

IDXGIOutputDuplication_AcquireNextFrame(this, TimeoutInMilliseconds, pFrameInfo, ByRef ppDesktopResource)
{
   hr := DllCall(NumGet(NumGet(this+0)+8*A_PtrSize), "ptr", this, "uint", TimeoutInMilliseconds, "ptr", pFrameInfo, "ptr*", ppDesktopResource)
   if hr or ErrorLevel
   {
      if (hr&=0xFFFFFFFF) = 0x887A0027   ; DXGI_ERROR_WAIT_TIMEOUT
         return "DXGI_ERROR_WAIT_TIMEOUT"
      _Error(A_ThisFunc " error: " hr "`nErrorLevel: " ErrorLevel)
   }
}

D3D11CreateDevice(pAdapter, DriverType, Software, Flags, pFeatureLevels, FeatureLevels, SDKVersion, ByRef ppDevice, ByRef pFeatureLevel, ByRef ppImmediateContext)
{
   hr := DllCall("D3D11\D3D11CreateDevice", "ptr", pAdapter, "int", DriverType, "ptr", Software, "uint", Flags, "ptr", pFeatureLevels, "uint", FeatureLevels, "uint", SDKVersion, "ptr*", ppDevice, "ptr*", pFeatureLevel, "ptr*", ppImmediateContext)
   if hr or ErrorLevel
      _Error(A_ThisFunc " error: " hr "`nErrorLevel: " ErrorLevel)
}

ID3D11Device_CreateTexture2D(this, pDesc, pInitialData, ByRef ppTexture2D)
{
   hr := DllCall(NumGet(NumGet(this+0)+5*A_PtrSize), "ptr", this, "ptr", pDesc, "ptr", pInitialData, "ptr*", ppTexture2D)
   if hr or ErrorLevel
      _Error(A_ThisFunc " error: " hr "`nErrorLevel: " ErrorLevel)
}

IDXGIOutputDuplication_MapDesktopSurface(this, pLockedRect)
{
   hr := DllCall(NumGet(NumGet(this+0)+12*A_PtrSize), "ptr", this, "ptr", pLockedRect)
   if hr or ErrorLevel
   {
      if (hr&=0xFFFFFFFF) = 0x887A0004   ; DXGI_ERROR_UNSUPPORTED
         return "DXGI_ERROR_UNSUPPORTED"
      _Error(A_ThisFunc " error: " hr "`nErrorLevel: " ErrorLevel)
   }
}

IDXGIOutputDuplication_UnMapDesktopSurface(this)
{
   hr := DllCall(NumGet(NumGet(this+0)+13*A_PtrSize), "ptr", this)
   if hr or ErrorLevel
      _Error(A_ThisFunc " error: " hr "`nErrorLevel: " ErrorLevel)
}

IDXGIOutputDuplication_ReleaseFrame(this)
{
   hr := DllCall(NumGet(NumGet(this+0)+14*A_PtrSize), "ptr", this)
   if hr or ErrorLevel
      _Error(A_ThisFunc " error: " hr "`nErrorLevel: " ErrorLevel)
}

IDXGIOutput1_DuplicateOutput(this, pDevice, ByRef ppOutputDuplication)
{
   hr := DllCall(NumGet(NumGet(this+0)+22*A_PtrSize), "ptr", this, "ptr", pDevice, "ptr*", ppOutputDuplication)
   if hr or ErrorLevel
      _Error(A_ThisFunc " error: " hr "`nErrorLevel: " ErrorLevel)
}

IDXGIOutput1_Query(IDXGIOutput)
{ 
   hr := ComObjQuery(IDXGIOutput, "{00cddea8-939b-4b83-a340-a685226666cc}")
   if !hr or ErrorLevel
      _Error(A_ThisFunc " error: " hr "`nErrorLevel: " ErrorLevel)
   return hr
}

ID3D11Texture2D_Query(desktop_resource)
{ 
   hr := ComObjQuery(desktop_resource, "{6f15aaf2-d208-4e89-9ab4-489535d34f9c}")
   if !hr or ErrorLevel
      _Error(A_ThisFunc " error: " hr "`nErrorLevel: " ErrorLevel)
   return hr
}

ID3D11DeviceContext_CopyResource(this, pDstResource, pSrcResource)
{
   hr := DllCall(NumGet(NumGet(this+0)+47*A_PtrSize), "ptr", this, "ptr", pDstResource, "ptr", pSrcResource)
   if ErrorLevel
      _Error(A_ThisFunc " error: " hr "`nErrorLevel: " ErrorLevel)
}

ID3D11DeviceContext_CopySubresourceRegion(this, pDstResource, DstSubresource, DstX, DstY, DstZ, pSrcResource, SrcSubresource, pSrcBox)
{
   hr := DllCall(NumGet(NumGet(this+0)+46*A_PtrSize), "ptr", this, "ptr", pDstResource, "uint", DstSubresource, "uint", DstX, "uint", DstY, "uint", DstZ, "ptr", pSrcResource, "uint", SrcSubresource, "ptr", pSrcBox)
   if ErrorLevel
      _Error(A_ThisFunc " error: " hr "`nErrorLevel: " ErrorLevel)
}

ID3D11DeviceContext_Map(this, pResource, Subresource, MapType, MapFlags, pMappedResource)
{
   hr := DllCall(NumGet(NumGet(this+0)+14*A_PtrSize), "ptr", this, "ptr", pResource, "uint", Subresource, "uint", MapType, "uint", MapFlags, "ptr", pMappedResource)
   if hr or ErrorLevel
      _Error(A_ThisFunc " error: " hr "`nErrorLevel: " ErrorLevel)
}

ID3D11DeviceContext_Unmap(this, pResource, Subresource)
{
   hr := DllCall(NumGet(NumGet(this+0)+15*A_PtrSize), "ptr", this, "ptr", pResource, "uint", Subresource)
   if ErrorLevel
      _Error(A_ThisFunc " error: " hr "`nErrorLevel: " ErrorLevel)
}

Release(this)
{
   DllCall(NumGet(NumGet(this+0)+2*A_PtrSize), "ptr", this)
   if ErrorLevel
      _Error(A_ThisFunc " error: " hr "`nErrorLevel: " ErrorLevel)
}

GUID(ByRef GUID, sGUID)
{
    VarSetCapacity(GUID, 16, 0)
    return DllCall("ole32\CLSIDFromString", "WStr", sGUID, "Ptr", &GUID) >= 0 ? &GUID : ""
}

_Error(val)
{
   msgbox % val
   ExitApp
}