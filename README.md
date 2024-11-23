# Curie

[![Build Status](https://github.com/macvmio/curie/actions/workflows/main.yml/badge.svg)](https://github.com/macvmio/curie/actions/workflows/main.yml)

## Overview

*Curie* is a lightweight, open-source virtualization solution, leveraging the Apple [Virtualization.framework](https://developer.apple.com/documentation/virtualization).

It allows users to run and manage isolated environments, making it easier to develop and test software in a controlled environment.

### Key Features

* **Containerization**: Like Docker, the tool allows users to create and manage containers, each providing a separate environment for running applications (under the hood, each container is represented by a standard macOS VM).

* **Resource Management**: The tool offers basic resource management options, allowing users to allocate CPU and memory resources to containers. This ensures that containers run efficiently without overloading the host system.

* **Image Management**: Users can create, modify, abd clone images. Images can be stored locally and reused across multiple containers.

## Installation

### Install via script

The following script will download [the latest version](https://github.com/macvmio/curie/releases/latest) of Curie from [GitHub Releases](https://github.com/macvmio/curie/releases) and install it in `/usr/local/bin/curie` (requires sudo for system-wide installation):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/macvmio/curie/refs/heads/main/.mise/tasks/install)"
```

Make sure you have the necessary permissions, as sudo may be required during the installation process.

## Usage

### Commands

#### Download an image restore file

```sh
curie download -p ~/Downloads/RestoreImage.ipsw
```

#### Build an image

```sh
curie build myteam/myimage/test-image:1.0 -i ~/Downloads/RestoreImage.ipsw -d "60 GB" 
```

#### Remove an image

```sh
curie rmi myteam/myimage/test-image:1.0
```

#### List images

```sh
curie images

# Example output

REPOSITORY                 TAG     IMAGE ID         CREATED         SIZE
myteam/myimage/ci/test     2.3     9bf95fe0f7f0     2 hours ago     60.03 GB
myteam/myimage/ci/test     2.1     7d5347edc7ca     7 hours ago     60.03 GB
```

The command has also `--format` (`-f`) parameter which allows to output JSON.

```sh
curie images -f json
```

Example output:
```json
[
  {
    "created" : "36 minutes ago",
    "image_id" : "a5abe5c92583",
    "repository" : "myteam\/myimage\/ci\/test",
    "size" : "60.03 GB",
    "tag" : "2.4"
  },
  {
    "created" : "4 days ago",
    "image_id" : "4b72a86471ef",
    "repository" : "myteam\/myimage\/ci\/test",
    "size" : "60.03 GB",
    "tag" : "2.3"
  },
  {
    "created" : "1 week ago",
    "image_id" : "7d5347edc7ca",
    "repository" : "myteam\/myimage\/ci\/test",
    "size" : "60.03 GB",
    "tag" : "2.1"
  }
]
```

#### Clone an image

```sh
curie clone myteam/myimage/test-image:1.0 myteam/myimage/test-image:1.1
```

#### Export an image

```sh
curie export a8302cc3e913 -p test-image-2.4.zip -c

# or without compression
curie export a8302cc3e913 -p test-image-2.4
```

#### Import an image

```sh
curie import myteam/myimage/test-image:2.4 -p test-image-2.4.zip
```

#### Start an ephemeral container

The container will be deleted after it is closed.

```sh
curie run myteam/myimage/test-image:1.0
```

#### Create a container

```sh
curie create myteam/myimage/test-image:1.0
```

#### List containers

```sh
curie ps

# Example output

CONTAINER ID     REPOSITORY                               TAG     CREATED           SIZE
7984867efb71     @7984867efb71/myteam/myimage/ci/test     2.1     3 minutes ago     60.03 GB
```

The command has also `--format` (`-f`) parameter which allows to output JSON.

#### Start a container

All changes that are made in the container will be applied to the image once the container is closed.

```sh
curie start @7984867efb71/myteam/myimage/ci/test
```

#### Inspect an image or a container

```sh
curie inspect myteam/myimage/ci/test:2.3

# Example output

Metadata:
  id: 9bf95fe0f7f0
  name: <none>
  createdAt: 2023-09-17T18:22:58Z
  network:
    devices:
      index: 0
      macAddress: 11:37:c4:2f:2a:a7

Config:
  name: test:2.3
  cpuCount: 8
  memorySize: 8.00 GB
  display:
    width: 1920px
    height: 1080px
    pixelsPerInch: 144
  network:
    devices:
      index: 0
      macAddress: synthesized
      mode: NAT
```

Inspect command supports `--format` (`-f`) parameter.

#### Edit config of an image or a container

The command will open the config file in the default text editor.

```sh
curie config myteam/myimage/ci/test:2.3
```

### Config file

`create` command allows to pass path to config file (`-c, --config-path <config-path>`). Config file describes basic properties of the virtual machine such as number of CPUs, RAM etc.

Example:

```json
{
  "cpuCount" : 8,
  "network" : {
    "devices" : [
      {
        "mode" : "NAT",
        "macAddress" : "synthesized"
      }
    ]
  },
  "display" : {
    "width" : 1920,
    "height" : 1080,
    "pixelsPerInch" : 144
  },
  "sharedDirectory": {
    "directories": [
      {
        "currentWorkingDirectory": {
          "options": {
            "name": "cwd",
            "readOnly": false
          }
        }
      }
    ]
  },
  "name" : "Test VM",
  "memorySize" : "8 GB"
}
```

### CPU count

Possible values:
* `<count>`, e.g. `8` - hardcoded number of CPUs
* `"minimumAllowedCPUCount"` - minimum number of CPUs
* `"maximumAllowedCPUCount"` - maximum number of CPUs

### Memory size

Possible values:
* `"<number> GB"`, e.g. `"80 GB"` - hardcoded size (user-friendly format)
* `"minimumAllowedMemorySize"` - minimum size
* `"maximumAllowedMemorySize"` - maximum size

### Display

Properties:
* `width` - width of the screen
* `height` - height of the screen
* `pixelsPerInch` - density

### Network

Currently we only support `NAT` interfaces. Each interface can have MAC address assigned in the following way:
* `"automatic"` - Virtualization Framework will transparently assign new MAC address
* `"synthesized"` - Curie will automatically generate unique MAC address per `run` or `start` operation (both MAC and IP address can be found using `curie inspect` command)
* e.g. `"6e:7e:67:0c:93:65"` - manual MAC address

### Shared directories

#### Share current working directory

Use `-s, --share-cwd` to share current working directory with the guest OS.

#### Share an arbitrary directory

Add the directory descriptor to `config.json`, e.g.

```json
{
 "sharedDirectory" : {
    "directories" : [
      {
        "directory": {
          "options": {
            "path": "/Users/marcin/shared-directory",
            "name": "shared-directory",
            "readOnly": false
          }
        }
      }
    ],
    "automount" : true
  }
}
```

#### Mount shared directories

A shared directory is automatically mounted via `/Volumes/My Shared Files` unless "automount" is disable via `config.json`, e.g.

```json
{
  "sharedDirectory" : {
    "directories" : [],
    "automount" : false
  }
}
```

If `automount` is set to `false`, the volume `curie` will need to be mounted manually, e.g.

```sh
# mounting shared directory
mkdir -p shared # you can pick up different name
mount -t virtiofs curie shared

# or
mkdir -p shared
mount_virtiofs curie shared
```

### Data location

By default, curie stores images and containers in `~/.curie` directory. You can change the location by setting `CURIE_DATA_ROOT` environment variable.

### Pull and Push Images

Curie does not natively support interacting with image registries (such as OCI), but it provides a flexible plugin system that allows you to extend its functionality. By creating lightweight plugins, you can easily add `pull` and `push` commands to interact with external image registries or storage backends.

This plugin system abstracts the integration entirely. Whether you are working with an OCI registry, an S3 bucket, or any other storage solution, the choice is yours. The image handling logic is completely within your control.

#### How to Add `pull` and `push` Plugins

To extend Curie with `pull` and/or `push` commands, follow these steps:

1. Navigate to the `~/.curie` directory (or your custom data directory if `CURIE_DATA_ROOT` is set).
2. Create a `plugins` directory inside.
3. Add executable files named `pull` and/or `push` to this directory.

Once these executable files are in place, Curie will automatically recognize them and include the new commands in its `--help` output. When a user runs a `pull` or `push` command, Curie will call the corresponding plugin scripts:

- `push --reference <reference>` will be executed when the user runs `curie push <reference>`.
- `pull --reference <reference>` will be executed when the user runs `curie pull <reference>`.

#### Pull Plugin Example

The following example shows a basic integration with [geranos](https://github.com/mobileinf/geranos).

```bash
#!/bin/bash -e

# Check if the number of arguments
if [[ $# -lt 2 ]]; then
    echo "Error: reference argument is required"
    echo "Usage: $0 --reference <reference>"
    exit 1
fi

# Check if the first argument is "--reference"
if [ "$1" != "--reference" ]; then
    echo "Error: reference argument is required"
    echo "Usage: $0 --reference <reference>"
    exit 1
fi

# Check if geranos is installed
if ! command -v geranos &> /dev/null; then
    echo "Error: geranos is not installed."
    exit 1
fi

# Call geranos
geranos pull "$2"
```

## Development

### Requirements

- Xcode 16.0 or newer
- mise

### Set up dev environment

Almost all `make <command>` commands require [mise](https://github.com/jdx/mise).

If you don't have mise installed, run the following command to install it.

```sh
make setup
```

### Build

Execute the commands below to build the project in debug mode.

```sh
make build 
make sign
```

### Run

Execute the commands below to run the project locally.

```sh
.build/debug/curie --help
```

### Build and Run in Xcode

The [Virtualization.framework](https://developer.apple.com/documentation/virtualization) requires the `com.apple.security.virtualization` entitlement to run correctly. Without this entitlement, certain commands, such as `start` or `run`, may fail and produce the following error:

```
Error: Invalid virtual machine configuration. The process doesn’t have the “com.apple.security.virtualization” entitlement.
Program ended with exit code: 1
```

To resolve this issue, you need to add the necessary entitlement to your app. Follow these steps to configure your Xcode project:

1. Open the Scheme Editor:
    - In Xcode, go to the Product menu and select **Scheme** > **Edit Scheme**.

2. Add a Post-Build Action:
    - In the Scheme editor, select the Build tab.
    - Under the **Post-actions** section, click the **+** button and choose New Run Script Action.

3. Enter the Codesign Command:
    - In the newly created **Run Script** action, enter the following command to apply the entitlement:

```sh
codesign --sign - --entitlements "$WORKSPACE_PATH/../../../Resources/curie.entitlements" --force "$TARGET_BUILD_DIR/curie"
```

4. Save and Build:
    - Save the scheme changes and rebuild the project. The app should now have the necessary entitlement to run the virtual machine without errors.

## Attributions

We would like to thank the authors and contributors of the following projects:

- [Virtualization.framework](https://developer.apple.com/documentation/virtualization)
- [swift-argument-parser](https://github.com/apple/swift-argument-parser)
- [swift-tools-support-core](https://github.com/apple/swift-tools-support-core)
- [SwiftLint](https://github.com/realm/SwiftLint)
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat)
- [mise](https://github.com/jdx/mise)

## License

Curie is released under version 2.0 of the [Apache License](LICENSE).
