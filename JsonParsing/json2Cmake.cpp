/*
The MIT License (MIT)

Copyright (c) 2014 LayfonWeller

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
#include "picojson.h"
#include <string>
#include <iostream>
#include <fstream>
#include <sstream>
#include <algorithm>


void isObject(const std::string &basename, const picojson::value::object& obj, std::ostream &out);
void isArray (const std::string &baseName, const picojson::value::array& obj, std::ostream &out);
void TestValue (const std::string &baseName, const picojson::value& val, std::ostream &out);

/*template<class T>
void CMakeSetPrint(const std::string keyName, const T value, std::ostream &out);*/
template<class T>
void CMakeSetPrint( std::string keyName, const T &value, std::ostream &out);

template<>
void CMakeSetPrint(std::string keyName, const picojson::object &value, std::ostream &out)
{
	std::replace( keyName.begin(), keyName.end(), ' ', '_');
	out << "set (  jsonParsed_" << keyName << " OBJECT";
	for (picojson::value::object::const_iterator i = value.begin(); i != value.end(); ++i)
	{
		std::string tmpCpy = i->first;
		std::replace( tmpCpy.begin(), tmpCpy.end(), ' ', '_');
		out << ";" << tmpCpy;
	}
	out << ")" << std::endl;
}
template<>
void CMakeSetPrint( std::string keyName, const picojson::array &value, std::ostream &out)
{
	std::replace( keyName.begin(), keyName.end(), ' ', '_');
	out << "set (  jsonParsed_"<< keyName << " ARRAY;" << value.size() << ")" << std::endl;
}
template<>
void CMakeSetPrint( std::string keyName, const bool &value, std::ostream &out)
{
	std::replace( keyName.begin(), keyName.end(), ' ', '_');
	out << "set (  jsonParsed_"<< keyName << " VALUE;" << ( value ? "TRUE" : "FALSE" )<< ")" << std::endl;
}
template<class T>
void CMakeSetPrint( std::string keyName, const T &value, std::ostream &out)
{
	std::replace( keyName.begin(), keyName.end(), ' ', '_');
	out << "set (  jsonParsed_"<< keyName << " VALUE;" << value << ")" << std::endl;
}

const std::string operator+(std::string const &a, const int &b)
{
	std::ostringstream oss;
	oss<<a<<b;
	return oss.str();
}

int main(int argc, char **argv)
{
	if (argc < 3)
		return -1;

	//printf ("Reading json file %s\n", argv[1]);

	std::ifstream jsonfile (argv[1]);

	picojson::value jsonObj;
	picojson::parse(jsonObj, jsonfile);
	
	std::ostream *somestream;
	if (argc > 3)
		somestream = new std::ofstream (argv[3]);
	else 
		somestream = &std::cout;
		
	
	std::string err = picojson::get_last_error();
	if (! err.empty()) 
	{
	  std::cerr << err << std::endl;
	  exit(1);
	}

	// check if the type of the value is "object"
	if (! jsonObj.is<picojson::object>()) {
	  std::cerr << "JSON is not an object" << std::endl;
	  exit(2);
	}

	// obtain a const reference to the map, and print the contents
	const picojson::value::object& obj = jsonObj.get<picojson::object>();
	CMakeSetPrint(argv[2], obj, *somestream);
	isObject(argv[2],obj, *somestream);
}

void isObject(const std::string &baseName, const picojson::value::object& obj, std::ostream &out)
{
	for (picojson::value::object::const_iterator i = obj.begin(); i != obj.end(); ++i)
	{
		TestValue(baseName+"_"+i->first, i->second, out);
	}
}

void isArray (const std::string &baseName, const picojson::value::array& obj, std::ostream &out)
{
	int j = 0;
	for (picojson::value::array::const_iterator i = obj.begin(); i != obj.end(); ++i)
	{
		TestValue(baseName+"_"+j, *i, out);
		++j;
	}
}

void TestValue (const std::string &baseName, const picojson::value& val, std::ostream &out)
{
	if (val.is<picojson::array>())
	{
		const picojson::value::array& subArray = val.get<picojson::array>();
		CMakeSetPrint(baseName, subArray , out);
		isArray( baseName, subArray,out);
	}
	else if (val.is<picojson::object>())
	{
		const picojson::value::object& subObj = val.get<picojson::object>();
		CMakeSetPrint(baseName, subObj, out);
		isObject(baseName,subObj,out);
	}
	else if (val.is<bool>())
	{
		CMakeSetPrint(baseName, val.get<bool>() , out);
	}
	else if (val.is<double>())
	{
		CMakeSetPrint(baseName, val.get<double>() , out);
	}
	else if (val.is<std::string>())
	{
		CMakeSetPrint(baseName, val.get<std::string>() , out);
	}
	else if (val.is<picojson::null>())
	{
		CMakeSetPrint(baseName, "" , out);
	}
	else
	{
		std::cerr << "Got a value from an unknown type! " << val.to_str() << std::endl;
	}
}


