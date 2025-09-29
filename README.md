## 🏗️ Project Structure
cocochip-classifier/
├── src/ # Source Verilog files
│ ├── cocochip_classifier.sv # Main classification module
│ ├── debouncer.sv # Button debouncing module
│ └── fpga_top.sv # Top-level FPGA integration
├── quartus/ # Quartus Project and Pin Assignment


## 🎯 Features
- 4-State FSM (IDLE, SAMPLING, CLASSIFY, DISPLAY)
- Three-channel ADC sampling (High, Mid, Low frequencies)
- Button debouncing for reliable inputs in FPGA
- LED output for classification results

## 📊 Classification Results
- LEDR0 = Mala-Uhog (Low peak dominant)
- LEDR1 = Malakanin (Mid peak dominant)  
- LEDR2 = Malatenga (High peak dominant)

## 🚀 Quick Start
1. Open in Quartus Prime
2. Compile and program to DE1-SoC board
4. Use KEY[0] to reset data, KEY[1] to start
5. Toggle SW[7:0] to imitate 8-bit data from an ADC
6. Press KEY[2] to imitate end of conversion of an ADC
7. Repeat 5 & 6 to get data from Malakanin and Malatenga
8. Read results on LEDR[2:0]
9. LEDR[9:8] shows which channel is being sampled (0-Mala-Uhog, 01-Malakanin, 10-Malatenga)
