#include <iostream>
#include <fstream>
#include <string>
using namespace std;

int main2 () {
	ofstream file;
	file.open ("bla.csv");
	std::string x;


	while(true){
		std::cin >> x;
		if(x == "Stop") {
		break;
	}

	file << x << "; ";
	}

  file.close();
  return 0;
}

