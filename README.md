# Sovereign Pi

Build a modular Raspberry PI server, based on  Nix. It is  designed to help you take full control of your Raspberry Pi with a focus on securit andd self, privacy, and self-sovereignty.

It is recommended that you use a Raspberry PI 5 with an NVME drive, but other block devices can be used with minor modifications.

The setup include  an automated configurations for LUKS encryption, Btrfs, Docker, and Portainer, allowing you to build a robust, secure, and flexible environment from the ground up.

## Features

- **LUKS Encryption**: Protect your data with full disk encryption.
- **Btrfs Filesystem**: Utilize advanced filesystem features such as snapshots and compression.
- **Docker & Portainer**: Run and manage your containers with ease.
- **Modular Flake Architecture**: Easily extend and customize the setup to suit your needs.

## Getting Started

### Prerequisites

- **Raspberry Pi** or a similar ARM-based device.
- **Nix** package manager installed on your system.

### Installation

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/yourusername/SovereignPi.git
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
