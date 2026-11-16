# SkySaga: Infinite Isles local server

Run the cancelled SkySaga client against a local server emulator. The emulator is based on [EDITzDev/SkySaga](https://github.com/EDITzDev/SkySaga).

## Quick start

1. Download client build **10414**: [archive.org](https://archive.org/details/sky-saga-infinite-isles).
2. Extract it into `game\`, so that `game\...\Client\SkySaga.exe` exists.
3. Double-click **`Play.bat`**.

The first run installs the .NET 9 SDK (via winget) if needed and builds the servers. After that it starts the web and game servers and launches the client.

| Option | Effect |
|---|---|
| `Play.bat -ServersOnly` | Start the servers without the client |
| `Play.bat -Rebuild` | Force a rebuild |

## Status

- Only client **10414** is supported. You can load in-game, but most gameplay isn't implemented.
- Build 38328 (Beta 1) is not supported: it is protected with Themida and crashes on Windows 11 before it contacts the server.

## Ports

| Service | Port |
|---|---|
| Web API | `localhost:5164` (HTTP) |
| Game server | UDP `42069` |

## More

- [Wiki](https://github.com/EDITzDev/SkySaga/wiki)
- [SkySaga Archive](https://etithespir.it/skysaga)
