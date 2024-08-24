# LUKS + Btrfs Setup Flake

This Nix flake provides an easy and secure way to set up LUKS encryption on a storage device with Btrfs as the underlying filesystem. It includes user-friendly prompts to guide you through selecting the appropriate devices and creating keyfiles, ensuring your data is encrypted and safe.

## Features

- **LUKS Encryption**: Secure your storage device using LUKS with a keyfile.
- **Btrfs Filesystem**: Set up Btrfs on your encrypted device.
- **Systemd Integration**: Automates the unlocking and mounting process on boot.
- **User Prompts**: Interactive dialogs guide you through device selection and configuration.

## Usage

1. **Install Nix**: Ensure you have Nix installed on your system.

2. **Clone the Repository**:
   ```sh
   git clone <your-repo-url>
   cd luks-btrfs-flake
   ```

3. **Run the Setup**

   ```sh
   nix run .#luksSetup
   ```

The systemd service will be installed and automatically unlocks and mount the encrypted data storage device.

## Important Notes

* **Data Loss Warning**: Formatting your device with LUKS will irrevocably erase all data. Additionally, if you lose the decryption key file, all data will be lost. Ensure you back up your keyfile securely and select the correct devices during setup.
* **Keyfile Safety**: The keyfile is crucial for accessing your encrypted data. After use, the keyfile device should be removed to prevent unauthorized access.
