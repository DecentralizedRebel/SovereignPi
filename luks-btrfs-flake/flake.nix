{
  description = "Set up LUKS encryption and Btrfs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = { self, nixpkgs }: let
    system = "aarch64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    # The default package for LUKS + Btrfs setup
    defaultPackage.${system} = pkgs.stdenv.mkDerivation {
      name = "luks-btrfs-setup";

      buildInputs = [
        pkgs.cryptsetup
        pkgs.btrfs-progs
        pkgs.dialog       # Tool for interactive prompts
        pkgs.systemd      # To install systemd services
        pkgs.notify-send  # For GUI notifications (optional)
      ];

      # Install phase to generate the unlock-and-mount script
      installPhase = ''
        mkdir -p $out/bin
        
        # Generate the unlock-and-mount.sh script during the install phase
        cat <<EOF > $out/bin/unlock-and-mount.sh
        #!/usr/bin/env bash

        # Function to list all block devices and prompt the user to select one
        select_block_device() {
          while true; do
            # List all block devices, including disks and partitions, and format the output cleanly
            BLOCK_DEVICES=\$(lsblk -ndo NAME,SIZE,TYPE,UUID | awk '\$3 == "disk" || \$3 == "part" {print "/dev/" \$1 " (" \$2 "B, UUID: " \$4 ")"}')
            if [ -z "\$BLOCK_DEVICES" ]; then
              dialog --msgbox "No suitable devices detected. Please insert a storage device and press OK to try again." 10 60
              continue
            fi

            CHOICE=\$(dialog --menu "Select the block device to use:" 15 60 4 \$(echo \$BLOCK_DEVICES) 3>&1 1>&2 2>&3)
            if [ -n "\$CHOICE" ]; then
              DEVICE=\$(echo \$CHOICE | awk '{print \$1}')
              UUID=\$(lsblk -no UUID \$DEVICE)
              echo "Selected block device: \$DEVICE with UUID: \$UUID"
              break
            fi
          done
        }

        # Prompt to select the block device containing the keyfile
        dialog --msgbox "First, select the device that will store the LUKS keyfile. This device should be backed up, because you cannot access your encrypted data without it!" 10 60
        select_block_device
        KEYFILE_DEVICE=\$DEVICE
        KEYFILE_MOUNT_POINT="/media/\$(whoami)/\$UUID"
        USB_KEY_PATH="luks-keyfile"  # Default keyfile name

        # Prompt the user to select the block device for LUKS-encrypted storage
        dialog --msgbox "Select the device that will be used for LUKS-encrypted storage." 10 60
        select_block_device
        STORAGE_DEVICE=\$DEVICE

        echo "Using keyfile device path: \$KEYFILE_MOUNT_POINT"
        echo "Using storage device: \$STORAGE_DEVICE"

        # Store the paths and filenames for later use
        echo "KEYFILE_DEVICE=\$KEYFILE_DEVICE" > $out/bin/luks-btrfs-config
        echo "KEYFILE_MOUNT_POINT=\$KEYFILE_MOUNT_POINT" >> $out/bin/luks-btrfs-config
        echo "USB_KEY_PATH=\$USB_KEY_PATH" >> $out/bin/luks-btrfs-config
        echo "STORAGE_DEVICE=\$STORAGE_DEVICE" >> $out/bin/luks-btrfs-config

        if ! mountpoint -q \$KEYFILE_MOUNT_POINT; then
          echo "Mounting keyfile device at \$KEYFILE_MOUNT_POINT"
          mkdir -p \$KEYFILE_MOUNT_POINT
          mount \$KEYFILE_DEVICE \$KEYFILE_MOUNT_POINT || { echo "Failed to mount keyfile device."; exit 1; }
        fi

        # Check if the LUKS device is already setup
        if cryptsetup isLuks \$STORAGE_DEVICE; then
          echo "LUKS device \$STORAGE_DEVICE already exists."
          if [ -f \$KEYFILE_MOUNT_POINT/\$USB_KEY_PATH ]; then
            echo "Keyfile found. Proceeding with LUKS unlock..."
            cryptsetup luksOpen \$STORAGE_DEVICE data --key-file \$KEYFILE_MOUNT_POINT/\$USB_KEY_PATH
            mount /dev/mapper/data \$KEYFILE_MOUNT_POINT
            umount \$KEYFILE_MOUNT_POINT
            notify-send "LUKS Unlock" "The keyfile device has been unmounted. Please remove it to prevent key leakage."
          else
            echo "Keyfile not found at \$KEYFILE_MOUNT_POINT/\$USB_KEY_PATH."
            while true; do
              CHOICE=\$(dialog --menu "Keyfile not found. What would you like to do?" 15 60 4 \
                1 "Generate a new random keyfile" \
                2 "Try again after inserting the keyfile device" \
                3 "Re-select keyfile device" 3>&1 1>&2 2>&3)

              case \$CHOICE in
                1)
                  echo "Generating new keyfile at \$KEYFILE_MOUNT_POINT/\$USB_KEY_PATH..."
                  dd if=/dev/urandom of=\$KEYFILE_MOUNT_POINT/\$USB_KEY_PATH bs=4096 count=1
                  chmod 600 \$KEYFILE_MOUNT_POINT/\$USB_KEY_PATH
                  echo "New keyfile generated."
                  break
                  ;;
                2)
                  echo "Please insert the keyfile device and press Enter to try again."
                  read -r
                  if [ -f \$KEYFILE_MOUNT_POINT/\$USB_KEY_PATH ]; then
                    echo "Keyfile found. Proceeding with LUKS unlock..."
                    cryptsetup luksOpen \$STORAGE_DEVICE data --key-file \$KEYFILE_MOUNT_POINT/\$USB_KEY_PATH
                    mount /dev/mapper/data \$KEYFILE_MOUNT_POINT
                    umount \$KEYFILE_MOUNT_POINT
                    notify-send "LUKS Unlock" "The keyfile device has been unmounted. Please remove it to prevent key leakage."
                    break
                  else
                    echo "Keyfile still not found."
                  fi
                  ;;
                3)
                  echo "Re-selecting keyfile device..."
                  select_block_device
                  ;;
                *)
                  echo "Invalid choice. Exiting."
                  exit 1
                  ;;
              esac
            done
          fi
        else
          dialog --yesno "No LUKS partition found on \$STORAGE_DEVICE. Do you want to format and encrypt this device with LUKS?" 10 60
          if [ \$? -eq 0 ]; then
            echo "Formatting and setting up LUKS on \$STORAGE_DEVICE..."
            cryptsetup luksFormat \$STORAGE_DEVICE --key-file \$KEYFILE_MOUNT_POINT/\$USB_KEY_PATH
            cryptsetup luksOpen \$STORAGE_DEVICE data --key-file \$KEYFILE_MOUNT_POINT/\$USB_KEY_PATH
            if ! blkid -o value -s TYPE /dev/mapper/data | grep -q "btrfs"; then
              echo "No Btrfs filesystem found. Creating a new Btrfs filesystem on /dev/mapper/data..."
              mkfs.btrfs /dev/mapper/data
            else
              echo "Btrfs filesystem already exists on /dev/mapper/data."
            fi
            mount /dev/mapper/data \$KEYFILE_MOUNT_POINT
            umount \$KEYFILE_MOUNT_POINT
            notify-send "LUKS and Btrfs Setup" "The storage device has been encrypted and formatted with Btrfs. Please remove the keyfile device to prevent key leakage."
          else
            echo "LUKS setup aborted by the user."
            exit 1
          fi
        fi
        EOF

        chmod +x $out/bin/unlock-and-mount.sh
      '';

      shellHook = ''
        echo "LUKS and Btrfs setup environment ready."
      '';
    };

    # Systemd service files with dynamically managed paths
    systemdServices = {
      unlockAndMount = pkgs.writeTextFile {
        name = "unlock-and-mount.service";
        destination = "/etc/systemd/system/unlock-and-mount.service";
        text = ''
          [Unit]
          Description=Unlock LUKS and mount Btrfs
          After=local-fs.target
          Requires=local-fs.target

          [Service]
          Type=oneshot
          ExecStart=${self.defaultPackage.${system}}/bin/unlock-and-mount.sh
          RemainAfterExit=true

          [Install]
          WantedBy=multi-user.target
        '';
      };
    };

    # Exposing a script for installation that uses the generated config
    apps.${system}.luksSetup = {
      type = "app";
      program = "${pkgs.writeScript "install-luks-btrfs" ''
        #!/usr/bin/env bash
        echo "Starting LUKS and Btrfs setup using previously selected devices and paths..."

        # Source the generated config file
        source $out/bin/luks-btrfs-config

        echo "Using keyfile device: \$KEYFILE_DEVICE"
        echo "Using keyfile mount point: \$KEYFILE_MOUNT_POINT"
        echo "Using storage device: \$STORAGE_DEVICE"
        echo "Using keyfile path: \$KEYFILE_MOUNT_POINT/\$USB_KEY_PATH"
        
        # Check if the LUKS device is already setup
        if cryptsetup isLuks $STORAGE_DEVICE; then
          echo "LUKS device $STORAGE_DEVICE already exists."
        else
          echo "Setting up LUKS device on $STORAGE_DEVICE..."
          cryptsetup luksFormat $STORAGE_DEVICE --key-file $KEYFILE_MOUNT_POINT/$USB_KEY_PATH
        fi

        # Check if the Btrfs filesystem is already present
        if blkid -o value -s TYPE $STORAGE_DEVICE | grep -q "btrfs"; then
          echo "Btrfs filesystem already exists on $STORAGE_DEVICE."
        else
          echo "Creating Btrfs filesystem on $STORAGE_DEVICE..."
          cryptsetup luksOpen $STORAGE_DEVICE data --key-file $KEYFILE_MOUNT_POINT/$USB_KEY_PATH
          mkfs.btrfs /dev/mapper/data
        fi

        # Install the systemd service
        echo "Installing systemd service..."
        cp ${self.systemdServices.unlockAndMount} /etc/systemd/system/
        systemctl enable unlock-and-mount.service
        systemctl start unlock-and-mount.service

        echo "LUKS and Btrfs setup completed."
      ''}";
    };
  };
}

