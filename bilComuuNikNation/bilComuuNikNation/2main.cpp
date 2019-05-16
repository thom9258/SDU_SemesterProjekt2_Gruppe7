#include <iostream>
#include <fstream>
#include <string>

#ifdef _WIN32
#include <io.h>
#else
#include <unistd.h>
#endif

#include "SerialPort.hpp"

using namespace std;
using namespace rwhw;


int main2()
{
	unsigned int tries = 0;

	SerialPort serial;
	std::string comPort = "COM10";


	serial.open(comPort, SerialPort::Baud9600, SerialPort::Data8, SerialPort::None, SerialPort::Stop1_0);


	ofstream file;
	std::string filename;
	int seconds;
	

	std::cout << "filnavn: ";
	std::cin >> filename;

	std::cout << "seconds: ";
	std::cin >> seconds;

	int iterations = 255 / 5 * seconds; //hvor kommer 5-tallet fra?!?! 

	filename.append(".csv");
	file.open(filename, fstream::app);
	// Flush
	serial.clean();

	for (unsigned char i = 0; i < iterations; ++i) {
		Sleep((seconds * 1000) / iterations);
		char buf[1];
		serial.read(buf, 1);
		//std::cout << (int) buf[0] << "\t" << (int) buf[1] << "\t" << (int) buf[2] << std::endl;
		file << (int)(unsigned char) buf[0] << "; ";
		serial.clean();
	}

	serial.close();
	file.close();
	return 0;
}

