# Pc info on which the simulator has been tested 

        inxi -Fz

        
        System:
        Kernel: 5.15.0-139-generic x86_64 bits: 64 
        Desktop: Gnome 3.36.9 
        Distro: Ubuntu 20.04.6 LTS (Focal Fossa) 
        Machine:
        Type: Laptop System: Dell 
        product: Dell G15 Special Edition 5521 v: N/A 
        serial: <filter> 
        Mobo: Dell model: 0371KJ v: A01 serial: <filter> 
        UEFI: Dell v: 1.42.0 date: 05/26/2026 
        Battery:
        ID-1: BAT0 charge: 41.9 Wh 
        condition: 41.9/84.3 Wh (50%) 
        CPU:
        Topology: 10-Core 
        model: 12th Gen Intel Core i7-12700H bits: 64 
        type: MT MCP L2 cache: 24.0 MiB 
        Speed: 2300 MHz min/max: 400/4600 MHz 
        Core speeds (MHz): 1: 2299 2: 2298 3: 2298 4: 2298 
        5: 2128 6: 2131 7: 2126 8: 2126 9: 2218 10: 2210 
        11: 2210 12: 2213 13: 2303 14: 2306 15: 2312 16: 2309 
        17: 2299 18: 2299 19: 2310 20: 2307 
        Graphics:
        Device-1: Intel driver: i915 v: kernel 
        Device-2: NVIDIA driver: nvidia v: 570.133.07 
        Display: x11 server: X.Org 1.20.13 driver: nvidia resolution: 2560x1440~240Hz, 
        1920x1080~60Hz, 1920x1080~60Hz 
        OpenGL: 
        renderer: NVIDIA GeForce RTX 3060 Laptop GPU/PCIe/SSE2 
        v: 4.6.0 NVIDIA 570.133.07 
        Audio:
        Device-1: Intel driver: sof-audio-pci-intel-tgl 
        Device-2: NVIDIA driver: snd_hda_intel 
        Device-3: Sony DualShock 4 [CUH-ZCT2x] type: USB 
        driver: snd-usb-audio,sony,usbhid 
        Sound Server: ALSA v: k5.15.0-139-generic 
        Network:
        Device-1: Intel driver: iwlwifi 
        IF: wlp0s20f3 state: down mac: <filter> 
        Device-2: Realtek driver: r8169 
        IF: enp58s0 state: down mac: <filter> 
        Device-3: Realtek RTL8153 Gigabit Ethernet Adapter 
        type: USB driver: r8152 
        IF: enxa0cec8e1c6da state: up speed: 1000 Mbps 
        duplex: full mac: <filter> 
        IF-ID-1: br-2928e49ccd0e state: down mac: <filter> 
        IF-ID-2: br-2a1f91e3219d state: down mac: <filter> 
        IF-ID-3: br-d590ab0fa9b3 state: down mac: <filter> 
        IF-ID-4: docker0 state: down mac: <filter> 
        IF-ID-5: docker_gwbridge state: down mac: <filter> 
        IF-ID-6: mpqemubr0 state: down mac: <filter> 
        IF-ID-7: ztdiyrn5tr state: unknown speed: 10 Mbps 
        duplex: full mac: <filter> 
        IF-ID-8: ztksetiecy state: unknown speed: 10 Mbps 
        duplex: full mac: <filter> 
        Drives:
        Local Storage: total: 1.86 TiB 
        used: 757.38 GiB (39.7%) 
        ID-1: /dev/nvme0n1 model: PC SN530 NVMe WDC 1024GB 
        size: 953.87 GiB 
        ID-2: /dev/sda type: USB vendor: Intenso model: SSD 
        size: 953.87 GiB 
        RAID:
        Hardware-1: Intel Volume Management Device NVMe RAID 
        Controller 
        driver: vmd 
        Partition:
        ID-1: / size: 457.53 GiB used: 408.39 GiB (89.3%) 
        fs: ext4 dev: /dev/nvme0n1p5 
        Sensors:
        System Temperatures: cpu: 74.0 C mobo: N/A 
        gpu: nvidia temp: 69 C 
        Fan Speeds (RPM): N/A 
        Info:
        Processes: 674 Uptime: 2h 00m Memory: 31.03 GiB 
        used: 16.73 GiB (53.9%) Shell: bash inxi: 3.0.38 


# Docker version Where the simulator was tested

        
        docker version


        Client: Docker Engine - Community
        Version:           28.1.1
        API version:       1.49
        Go version:        go1.23.8
        Git commit:        4eba377
        Built:             Fri Apr 18 09:52:18 2025
        OS/Arch:           linux/amd64
        Context:           default

        Server: Docker Engine - Community
        Engine:
        Version:          28.1.1
        API version:      1.49 (minimum version 1.24)
        Go version:       go1.23.8
        Git commit:       01f442b
        Built:            Fri Apr 18 09:52:18 2025
        OS/Arch:          linux/amd64
        Experimental:     false
        containerd:
        Version:          1.7.27
        GitCommit:        05044ec0a9a75232cad458027ca83437aae3f4da
        runc:
        Version:          1.2.5
        GitCommit:        v1.2.5-0-g59923ef
        docker-init:
        Version:          0.19.0
        GitCommit:        de40ad0

# Open this folder in vs code

        code .

# Load the image 

        docker load --input frasky_test.tar.gz


# Launch the simulator


        source start_sim.sh

# Inside container


        frasky_sim_start

# Follow the readme inside the sharefolder


        frasky_README.docx


# To stop the simulator


        frasky_sim_stop
