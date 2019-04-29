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
	ofstream file;
	file.open ("jaDetVedJegIkke.csv");
	// Flush
	serial.clean();

	for (unsigned char i = 0; i < 255; ++i) {
		Sleep(100);
		char buf[1];
		serial.read(buf, 1);
		//std::cout << (int) buf[0] << "\t" << (int) buf[1] << "\t" << (int) buf[2] << std::endl;
		file << buf << "; ";
	}

	serial.close();
	file.close();
	return 0;
}

