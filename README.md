# Sovereign Pi

Build a modular Raspberry PI server, based on  Nix. Designed to help you take full control of your Raspberry Pi, focusing on security and self-sovereignty.

It is recommended that you use a Raspberry PI 5 with an NVME drive, but other block devices can be used with less performance.

The setup includes an automated configurations for LUKS encryption, Btrfs, Docker, and Portainer, allowing you to build a robust, secure, and flexible environment from the ground up.

## Features

- **LUKS Encryption**: Protect your data with full disk encryption.
- **Btrfs Filesystem**: Utilize advanced filesystem features such as snapshots and compression.
- **Docker & Portainer**: Run and manage your containers with ease.
- **Modular Flake Architecture**: Easily extend and customize the setup.

## Getting Started

### Prerequisites

- **Raspberry Pi** or a similar ARM-based device.
- **Nix** package manager installed on your system.
- **USB stick* to host the LUKS Key file to automatically unlock your encrypted filesytsm
- **Storage device** Encrypted with LUKS, and formatted as BTRFS.

### Installation

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/DecentralizedRebel/SovereignPi.git
   cd SovereignPi
   ```

2. **Run the Setup:**

   ```bash
   nix develop
   ```

Follow the instructions to configure youd environment.


3. **Deploy systemd services:**
   ```bash
   ./result/bin/systemd-service-setup
   ```
