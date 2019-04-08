#include <iostream>

#ifdef _WIN32
#include <io.h>
#else
#include <unistd.h>
#endif

#include "SerialPort.hpp"

using namespace std;
using namespace rwhw;


int main()
{
    SerialPort serial;
    serial.open("COM4", SerialPort::Baud9600);

    // Flush
    serial.clean();

    for (unsigned char i = 0; i < 255; ++i) {
        char c[1];
        c[0] = '+';//static_cast<char>(i);
        serial.write(c, 1);
#ifdef _WIN32
        Sleep(100);
#else
        sleep(0.1);
#endif
        char buf[128];
        serial.read(buf, 1);
        //std::cout << (int) buf[0] << "\t" << (int) buf[1] << "\t" << (int) buf[2] << std::endl;
        std::cout << static_cast<int>(buf[0]) << std::endl;
    }

    serial.close();
}

