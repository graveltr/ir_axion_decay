#include <stdlib.h>
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <algorithm>

using namespace std;

void process_aor(string aor);
vector< vector<string> > process_query_table(string table_file);
vector<string> get_row_entries(string row, vector<int> header_idxs);
vector<string> get_header_entries(string row);
vector<int> get_header_idxs(string row);
string construct_query_link(string aor);

// utility
void print_row(vector< vector<string> > table, int row_idx);
void print_col(vector< vector<string> > table, int col_idx);
int find_col(vector< vector<string> > table, string label);
string clean_whitespace(string in);

int main() {
	string aor;
	ifstream myfile ("aors.txt");
	if (myfile.is_open()) {
		while ( getline (myfile,aor) ) {
			cout << "downloading AOR: " << aor << '\n';
			if(aor[0] != '#') // ignore comments
				process_aor(aor);
		}
		myfile.close();
	} else cout << "Unable to open file"; 
	return 0;
}

void process_aor(string aor){
	string query_link = construct_query_link(aor);
	string system_call = "wget --quiet " + query_link + " -O output.file";

	// wget system call to download query table
	int status = system(system_call.c_str());
	vector< vector<string> > table = process_query_table("output.file");

	int HEADER = 0;
	int TYPE = 1;

	int accessUrl_idx = find_col(table, "accessWithAnc1Url");
	if(accessUrl_idx == -1){
		cout << "accessURL col not found" << endl; 
		exit(0);
	}

	int wavelength_idx = find_col(table, "wavelength");
	if(wavelength_idx == -1){
		cout << "wavelength col not found" << endl; 
		exit(0);
	}

	int name_idx = find_col(table, "externalname");
	if(name_idx == -1){
		cout << "name col not found" << endl; 
		exit(0);
	}

	// bash tings
	status = system(("rm -rf datasets/r" + aor).c_str());
	status = system(("mkdir datasets/r" + aor).c_str());
	status = system(("mkdir datasets/r" + aor + "/ch0").c_str());
	status = system(("mkdir datasets/r" + aor + "/ch1").c_str());
	status = system(("mkdir datasets/r" + aor + "/ch0/bcd").c_str());
	status = system(("mkdir datasets/r" + aor + "/ch1/bcd").c_str());

	int DATA_START = 2;
	for(int j = DATA_START; j < table.size(); ++j){
		if(table[j][wavelength_idx].find("IRS SL") != string::npos ||
		   table[j][wavelength_idx].find("IRS SH") != string::npos){
			system_call = "wget --quiet --output-document=datasets/" 
			+ to_string(j) + ".zip \"" + 
			table[j][accessUrl_idx] + "\"";
			cout << "Downloading: " << table[j][name_idx] << endl;
			// cout << "system call > " << system_call << endl; 
			status = system(system_call.c_str());
			status = system(("unzip -d datasets datasets/" + to_string(j) + ".zip > /dev/null").c_str());
			status = system(("rm datasets/" + to_string(j) + ".zip").c_str());
		}
	}
	
	status = system("rm -rf output.file");
}

vector< vector<string> > process_query_table(string table_file){
	// row 0 is junk
	// row 1 is table header
	// row 2 is data type (int, string, etc)
	// row 3 ... is data
	string row;
	vector< vector<string> > table;
	vector<int> header_idxs;
	ifstream myfile (table_file);
	int i = 0;
	if (myfile.is_open()) {
		while ( getline (myfile,row) ) {
			if(i == 1 || i == 2){
				table.push_back(get_header_entries(row));
				if(i == 1) header_idxs = get_header_idxs(row);
			} else if (i != 0) table.push_back(get_row_entries(row, header_idxs));
			++i;
		}
		myfile.close();
	} else cout << "Unable to open file"; 
	return table;
}

// parse based on '|' delimiter (super annoying)
vector<string> get_header_entries(string row){
	vector<string> ret;
	istringstream row_stream(row);
	string entry;
	bool first = true;
	while(getline(row_stream, entry, '|')) { 
		if(first) first = false;
		else ret.push_back(entry);
	}
	for(int i = 0; i < ret.size(); ++i){
		ret[i] = clean_whitespace(ret[i]);
	}
	return ret;
}

// unfortunately all other rows aren't conveniently
// delimited, they are aligned with the header columns
// so need to make note of the string idx of each column
vector<int> get_header_idxs(string row){
	vector<int> ret;
	int curr_idx = row.find("|");
	while(curr_idx != string::npos){
		ret.push_back(curr_idx);
		curr_idx = row.find("|", curr_idx+1);
	}	
	return ret;
}

vector<string> get_row_entries(string row, vector<int> header_idxs){
	vector<string> ret;
	for(int i = 0; i < header_idxs.size() - 1; ++i)
		ret.push_back(row.substr(header_idxs[i] + 1, (header_idxs[i+1] - header_idxs[i])));
	// clean trailing spaces
	for(int i = 0; i < ret.size(); ++i){
		ret[i] = clean_whitespace(ret[i]);
	}
	return ret;
}

string construct_query_link(string aor){
	string query_link = 	"\"https://irsa.ipac.caltech.edu/applications/"
				"Spitzer/SHA/servlet/DataService?REQKEY=";
	query_link += aor;
	query_link += "&VERB=3&DATASET=ivo%3A%2F%2Firsa.ipac%2Fspitzer.level1\"";
	return query_link;
}

// utility
string clean_whitespace(string in){
	string whitespaces (" \t\f\v\n\r");
	int found = in.find_last_not_of(whitespaces);
	if (found!=string::npos)
		in.erase(found+1);
	else
		in.clear();            // str is all whitespace
	return in;
}

int find_col(vector< vector<string> > table, string label){
	int ret = -1;
	for(int i = 0; i < table[0].size(); ++i) 
		if(table[0][i] == label)
			return i;
	return ret;
}

void print_row(vector< vector<string> > table, int row_idx){
	cout << "[";
	for(int j = 0 ; j < table[row_idx].size(); ++j) 
		cout << table[row_idx][j] << ",";	
	cout << "]" << endl;
}

void print_col(vector< vector<string> > table, int col_idx){
	cout << "[";
	for(int j = 2 ; j < table.size(); ++j) 
		cout << table[j][col_idx] << ",";
	cout << "]" << endl;
}
