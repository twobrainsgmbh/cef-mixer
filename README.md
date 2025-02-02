# CEF Offscreen-Rendering (OSR) Mixer Demo

A sample application to demonstrate how to use the proposed `OnAcceleratedPaint()` callback when using CEF for HTML off-screen rendering.  This application uses D3D11 shared textures for CEF which improves the OSR rendering performance.

## Build Instructions

1. If you don't have it already - install CMake and Visual Studio 2022
    * Make sure to install C/C++ development tools

2. Download latest CEF to create a custom build or use an example binary distribution
    * Sample distribution support **Chromium 120**
    * [x64 sample binary distribution][x64_build] (Release build only)


    
> Note: The above sample distributions are not supported official builds - they are intended for testing/demo purposes.
    
3. From a command prompt set the environment variable **CEF_ROOT** to the location of your CEF binary distribution.  Then run the gen_vs2022.bat script.

```
> set CEF_ROOT=<path\to\cef\binary-distribution>
> gen_vs2022.bat
```

4. Replace the "cmakeCommandArgs" value with the correct path to the cef binary distribution like this: "-DCEF_ROOT:STRING=<path\to\cef\binary-distribution>"
Relative path is unfortunately not possible, the existing cmake architecture does not allow this, right now
![](CmakeSettings.png)

5. Open the build/cefmixer.sln solution in Visual Studio

> If using one of the sample binary distributions from step 2 - make sure to change the build configuration to **Release** since the distributions above do not contain **Debug** versions

6. Build the **ALL_BUILD** project

7. Browse to the subfolder: "bin\x64-Release\src\Release" or "bin\x64-Debug\src\Debug" (Requires the cef standard or binaries, minimal contains only release buils) and run the **cefmixer.exe** application

8.~~As the cef standard binary distribution does not support web-gpu we need download a chrome dev(canary build), best as a portable version (https://portableapps.com/apps/internet/google-chrome-portable-dev) and copy the cef binaries from there into the target directory of cef mixer once. The script CopyCEFWEBGPUtoOutDir.bat in the cef-mixer root dir will help with this task. Make sure to rebuild the cef-mixer solution after the script execution before running or debugging cef-mixer~~
## Usage
Once the cefmixer.exe is built, it can be run without any arguments - in which case it will automatically navigate to https://webglsamples.org/aquarium/aquarium.html

In addition to rendering an HTML view off-screen, the demo application will also create an overlay layer using a PNG image file (the red DEMO graphic in the screenshots below).

The following screenshot was taken when running on a gaming monitor at 144Hz:

![](SampleOutput.png)

### Multiple Views

The application can tile a url into layers arranged in a grid to test multiple HTML browser instances.  Each layer is an independent CEF Browser instance.  The following example uses the `--grid` command-line switch to specify a 2 x 2 grid:

```
cefmixer.exe http://webglsamples.org/dynamic-cubemap/dynamic-cubemap.html --grid=2x2
```

![Grid][demo3]

### Custom Layering

The command-line examples above work to get something running quickly.  However, it is also possible to define the layers using a simple JSON file.

For example, if the following is saved to a file called `composition.json` :

```json
{
  "width":960,
  "height":540,
  "layers": [
     {
       "type":"web",
       "src":"http://webglsamples.org/spacerocks/spacerocks.html"
     },
     {
       "type":"web",
       "src":"file:///C:/examples/overlay.svg",
       "left":0.5,
       "top":0.5,
       "width":0.5,
       "height":0.5			
     }
  ]
}
```

> Note: layer positions are in normalized 0..1 units where 0,0 is the top-left corner and 1,1 is the bottom-right corner.

We can run `cefmixer` using the above JSON layer description:

```
cefmixer.exe c:\examples\composition.json
```

![JSON][demo4]

The application uses the handy utility method `CefParseJSON` in CEF to parse JSON strings.

## Integration
The update to CEF proposes the following changes to the API for application integration.

1. Enable the use of shared textures when using window-less rendering (OSR).

```c
CefWindowInfo info;
info.SetAsWindowless(nullptr);
info.shared_texture_enabled = true;
```

2. Override the new `OnAcceleratedPaint` method in a `CefRenderHandler` derived class:

```c
void OnAcceleratedPaint(
		CefRefPtr<CefBrowser> browser,
		PaintElementType type,
		const RectList& dirtyRects,
		void* share_handle) override
{
}
```

`OnAcceleratedPaint` will be invoked rather than the existing `OnPaint` when `shared_texture_enabled` is set to true and Chromium is able to create a shared D3D11 texture for the HTML view.

3. Optionally enable the ability to issue BeginFrame requests

```c
CefWindowInfo info;
info.SetAsWindowless(nullptr);
info.shared_texture_enabled = true;
info.external_begin_frame_enabled = true;
```

At an interval suitable for your application, make the following call (see [web_layer.cpp](https://github.com/daktronics/cef-mixer/blob/master/src/web_layer.cpp) for a full example) :

```c
browser->GetHost()->SendExternalBeginFrame();
```

When using `SendExternalBeginFrame`, the default timing in CEF is disabled and the `windowless_frame_rate` setting is ignored.


## Room for Improvement
A future update could include the following 
 * ~~Allow the client application to perform SendBeginFrame by adding a new method to CEF's public interface.~~
     * ~~Chromium already supports an External BeginFrame source - CEF currently does not expose it directly.~~
     * **Update** this is now supported in the latest revision
 * Update `OffscreenBrowserCompositorOutputSurface` class to handle both the Reflector and a shared texture
     * This was attempted originally but ran into issues creating a complete FBO on the Reflector texture
     * Not a big deal for CEF applications, since CEF does not use the Reflector concept in Chromium anyway.
 * Take the Chromium changes directly to the Chromium team
     * We can get the job done with the patching system built into CEF to apply Chromium changes, but rather the shared texture FBO probably makes more sense as a pull request on Chromium itself.  Seems only reasonable applications that use Headless-mode in Chromium could also benefit from shared textures.

[demo1]: https://user-images.githubusercontent.com/2717038/37864646-def58a70-2f3f-11e8-9df9-551fe65ae766.png "Cefmixer Demo"
[demo2]: https://user-images.githubusercontent.com/2717038/37864824-a02a0648-2f41-11e8-9265-be60ad8bf8a0.png "No VSync"
[demo3]: https://user-images.githubusercontent.com/2717038/37864648-ea76954c-2f3f-11e8-90d6-4130e56086f4.png "Grid"
[demo4]: https://user-images.githubusercontent.com/2717038/37930171-9850afe0-3107-11e8-9a24-21e1b1996fa5.png "JSON"
[x64_build]: https://cef-builds.spotifycdn.com/index.html "x64 Distribution"
[pr158]: https://bitbucket.org/chromiumembedded/cef/pull-requests/158/support-external-textures-in-osr-mode/diff "Pull Request"
[changes]: https://github.com/daktronics/cef-mixer/blob/master/CHANGES.md "Walkthrough"

