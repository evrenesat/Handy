# AGENTS.windows-arm64-build.md

This file documents the practical build setup that worked for Handy on **Windows 11 ARM64**.

## Goal
Make local `tauri dev` and `tauri build` reliable on ARM64 Windows where:
- `node` is often `arm64`
- `bun` is often `x64`
- native optional deps can mismatch by architecture

## What Works

### 1) Use the launcher script
Use:
`scripts/dev-tauri-windows.bat`

It handles:
- VS Build Tools environment init
- Bun/Node/Cargo/CMake path discovery
- native optional dependency healing for Bun frontend deps
- port 1420 cleanup
- live console output + log file output (`logs/tauri-dev.log`)

### 2) Required local tools
- Visual Studio 2022 Build Tools (MSVC)
- CMake (VS-bundled CMake is used)
- Rust toolchain
- Bun + Node
- Vulkan SDK installed as **x64** (not ARM64), because current build target is x64 in this setup

## Known Architecture Pitfalls

### Node vs Bun arch mismatch
Common state:
- `node`: `win32 arm64`
- `bun`: `win32 x64`

This can break optional native packages unless both sides have matching platform packages.

Symptoms:
- `@tauri-apps/cli` native binding errors
- `@rollup/rollup-win32-...` not found
- `@esbuild/win32-...` mismatch
- `@tailwindcss/oxide-win32-...` mismatch

### Vulkan arch mismatch
If Vulkan SDK lib is ARM64 while link target is x64:
- `LNK4272` machine type conflict
- many Vulkan unresolved externals

Fix:
- Install Vulkan SDK x64
- Ensure `VULKAN_SDK` points to x64 SDK path

## Build-Specific Notes (local machine)

For local release build, this env set worked:
- `WHISPER_NATIVE=OFF`
- `GGML_NATIVE=OFF`
- `CMAKE=<VS-bundled cmake.exe>`
- `VULKAN_SDK=C:\VulkanSDK\1.4.341.1`
- `LIBCLANG_PATH` pointing to x64 libclang when needed

Why `WHISPER_NATIVE=OFF` / `GGML_NATIVE=OFF`:
- avoids fragile SIMD `try_run` path that produced Windows file-lock cleanup failures in this environment.

## Local-only Config Decisions

In local-fixes branch we disabled:
- Windows custom `signCommand`
- `createUpdaterArtifacts`

Reason:
- local machine lacked the signing CLI and updater private key.

These are local build conveniences and should not be assumed for upstream production release flow.

## Output Locations

After successful `tauri build`:
- `src-tauri/target/release/bundle/msi/Handy_0.7.3_arm64_en-US.msi`
- `src-tauri/target/release/bundle/nsis/Handy_0.7.3_arm64-setup.exe`

## Fast Triage Checklist

1. `scripts/dev-tauri-windows.bat`
2. Check `logs/tauri-dev.log`
3. If native-binding error, verify which package/arch is missing
4. Verify `VULKAN_SDK` points to x64 SDK
5. Verify `LIBCLANG_PATH` points to x64 LLVM clang DLLs
