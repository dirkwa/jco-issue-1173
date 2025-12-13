# .NET NativeAOT + jco Minimal Reproduction

Minimal test case for [jco issue #1173](https://github.com/bytecodealliance/jco/issues/1173).

## Problem

WASM components built with `componentize-dotnet` crash when transpiled with jco for Node.js/V8:

```
RuntimeError: null function or function signature mismatch
```

The same component works correctly with Wasmtime.

## Environment (tested)

- componentize-dotnet: 0.7.0-preview00010
- .NET SDK: 10.0.101
- jco: 1.15.4
- Node.js: 22.21.0
- wasi-sdk: 25.0 (auto-downloaded by componentize-dotnet)
- OS: Debian 13 (Linux x86_64)

## Reproduction Steps

### 1. Install dependencies

```bash
npm install
```

### 2. Build the component

```bash
# Set WASI_SDK_PATH if you have it installed (optional - componentize-dotnet downloads it)
export WASI_SDK_PATH=/opt/wasi-sdk-25.0-x86_64-linux

dotnet build -c Release
```

Output: `bin/Release/net10.0/wasi-wasm/publish/Minimal.wasm`

### 3. Transpile with jco

```bash
npx @bytecodealliance/jco transpile \
  bin/Release/net10.0/wasi-wasm/publish/Minimal.wasm \
  -o jco-output \
  --name minimal \
  --tla-compat
```

### 4. Run test

```bash
node test.mjs
```

**Expected:** Prints `"hello from dotnet"`

**Actual:**
```
Loading .NET WASM component via jco...
$init completed
Calling plugin.getId()...
Error: null function or function signature mismatch
RuntimeError: null function or function signature mismatch
    at S_P_CoreLib_System_Runtime_EH__DispatchException (wasm-function[1959])
    at S_P_CoreLib_Internal_Runtime_CompilerHelpers_ThrowHelpers__ThrowNullReferenceException (wasm-function[1335])
    at S_P_CoreLib_Internal_Runtime_CompilerHelpers_StartupCodeHelpers__InitializeGlobalTablesForModule (wasm-function[1242])
    at S_P_CoreLib_Internal_Runtime_CompilerHelpers_StartupCodeHelpers__InitializeModules (wasm-function[2180])
    at InitializeRuntime() (wasm-function[23])
    ...
```

## Technical Analysis

The error occurs during .NET runtime initialization (`InitializeGlobalTablesForModule`). The .NET NativeAOT compiler generates indirect call tables that initialize correctly in Wasmtime but fail in V8/jco.

The stack trace shows:
1. `wasmExportGetId` is called
2. `RhpReversePInvoke` triggers runtime initialization
3. `InitializeModules` -> `InitializeGlobalTablesForModule` fails
4. `ThrowNullReferenceException` is thrown but can't be dispatched (null function table entry)

This suggests the indirect call table that .NET NativeAOT relies on isn't being properly initialized by jco's generated JavaScript.

## Files

- `wit/minimal.wit` - WIT interface (simplest possible: one function returning a string)
- `PluginImpl.cs` - C# implementation
- `Minimal.csproj` - .NET project configuration
- `patch-threadstatic.sh` - Patches wit-bindgen output for WASI compatibility
- `test.mjs` - Node.js test that reproduces the error
- `nuget.config` - NuGet feeds for experimental packages

## Use Case

Building WASM plugins for [Signal K](https://signalk.org/) marine data server. AssemblyScript and Rust plugins work perfectly with jco - only .NET NativeAOT fails.
