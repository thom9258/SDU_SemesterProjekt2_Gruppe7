#include <iostream>
#include <string>
#include <bitset>
#include <vector>

#ifdef _WIN32
#include <io.h>
#else
#include <unistd.h>
#endif

#include "SerialPort.hpp"

using namespace std;
using namespace rwhw;

//function prototype
void sendStr(SerialPort &serial, std::string data);
void sendInt(SerialPort &serial, int data);

//fucking SDU's diffinitioner på ting
rwhw::SerialPort::Baudrate baud[8] = {
	SerialPort::Baud1200, 
	SerialPort::Baud2400,
	SerialPort::Baud4800,
	SerialPort::Baud9600,
	SerialPort::Baud19200,
	SerialPort::Baud38400,
	SerialPort::Baud57600,
	SerialPort::Baud115200
};
rwhw::SerialPort::DataBits databit[4] = {
	SerialPort::Data5,
	SerialPort::Data6,
	SerialPort::Data7,
	SerialPort::Data8
};
rwhw::SerialPort::Parity parity[6] = {
	SerialPort::Even,
	SerialPort::Mark,
	SerialPort::Odd,
	SerialPort::None,
	SerialPort::Odd,
	SerialPort::Space
};
rwhw::SerialPort::StopBits stopbit[3] = {
	SerialPort::Stop1_0,
	SerialPort::Stop1_5,
	SerialPort::Stop2_0
};

int main()
{
	
    SerialPort serial;

	std::cerr.setstate(std::ios_base::failbit); //disable std::cerr
	std::string comPort;
	unsigned long tries = 0;
	std::cout << "trying to connect\n";
	for (int sb = 0; sb <= 3; sb++) {
		for (int par = 0; par <= 6; par++) {
			for (int db = 0; db <= 4; db++) {
				for (int bo = 0; bo <= 8; bo++) {
					for (int port = 0; port <= 20; port++) {
						int tries = 0;
						while (tries++ < 1000) {
							if (serial.open(comPort, baud[bo], databit[db], parity[par], stopbit[sb])) {
								std::cout << "foud connection at" << comPort << bo << db << par;
								goto Freedome;
							}
						}
						//std::cout << "trying new port \n";
					}
					std::cout << "trying new baudrate \n";
				}
				std::cout << "trying new databit \n";
			}
			std::cout << "trying new parity \n";
		}
		std::cout << "trying new stopbit \n";
	}
	Freedome:
	std::cerr.clear(); //enable std::cer

	std::string input;
	char output[128], buff[128];
	int inputLength;
	bool number;

    // Flush
	while (true) {
		serial.clean();
		std::cout << "input: ";
		std::cin >> input;

		//stop hvis indput er "stop"
		if (input == "stop")
			break;

		//test om indput er et tal
		try
		{
			stoi(input);
			number = true;
		}
		catch (const std::exception&)
		{
			number = false;
		}

		//hvis input er tal, send tal ellers send char array
		if (number) {
			if (input.length() == 8) {
				int num;
				num = std::stoi(input);
				//num = convertBinaryToDecimal(num);
				sendInt(serial, num);
				Sleep(100);
				serial.read(buff, 1);
				std::cout << "read from atmega: " << (int)buff[0];
			}
			else {
				sendInt(serial, stoi(input));
				Sleep(100);
				serial.read(buff, 1);
				std::cout << "read from atmega: " << (int)buff[0];
			}
		}
		else {
			sendStr(serial, input);
			Sleep(100);
			serial.read(buff, (input.length()));
			std::cout << "read from atmega: ";
			for (int i = 0; i < (input.length()); i++) {
				std::cout << static_cast<char>(buff[i]);
			}
		}
	
		
		//std::cout << (int) buf[0] << "\t" << (int) buf[1] << "\t" << (int) buf[2] << std::endl;
		
		std::cout << "\n" << std::endl;
	}
    serial.close();
	return 0;
}


void sendInt(SerialPort &serial, int data) {
	char output[128];
	if (data >= 256)
		std::cout << "number biggere than 255, write a lower number" << std::endl;
	else {
		std::cout << "type: integer" << std::endl;
		std::cout << "value " << data << std::endl;
		std::cout << "binary value " << std::bitset<8>(data) << std::endl;
		output[0] = static_cast<char>(data);
		serial.write(output, 1);
	}
}

int convertBinaryToDecimal(long n)
{
	int decimalNumber = 0, i = 0, remainder;
	while (n != 0)
	{
		remainder = n % 10;
		n /= 10;
		decimalNumber += remainder * pow(2, i);
		++i;
	}
	return decimalNumber;
}

void sendStr(SerialPort &serial, std::string data) {
	int inputLength = data.length();
	char output[128];
	std::cout << "type: string" << std::endl;
	std::cout << "size: " << inputLength << std::endl;
	std::cout << "value: ";
	for (int i = 0; i < inputLength; i++) {
		std::cout << static_cast<int>(data[i]) << " ";
	}
	std::cout << std::endl;

	std::cout << "binary value: ";
	for (int i = 0; i < inputLength; i++) {
		std::cout << std::bitset<8>(static_cast<int>(data[i])) << " ";
		output[i] = static_cast<char>(data[i]);
	}
	std::cout << std::endl;

	serial.write(output, inputLength);
}
