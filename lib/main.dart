import 'package:flutter/material.dart';

void main() {
  runApp(const NamazApp());
}

class NamazApp extends StatelessWidget {
  const NamazApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Namaz Tracker',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}

// ---------------- USER DATA RECORD STORE ----------------
class UserDatabase {
  static final Map<String, List<Map<String, dynamic>>> _userRecords = {};

  static List<Map<String, dynamic>> getRecords(String email) {
    return _userRecords[email] ?? [];
  }

  static void addOrUpdateRecord(String email, Map<String, dynamic> record) {
    _userRecords.putIfAbsent(email, () => []);
    List<Map<String, dynamic>> records = _userRecords[email]!;

    int existingIdx = records.indexWhere((element) => element['date'] == record['date']);
    if (existingIdx != -1) {
      records[existingIdx] = record;
    } else {
      records.insert(0, record);
    }
  }

  static String generateCSV(String email) {
    List<Map<String, dynamic>> records = getRecords(email);
    String csv = "Date,Fajar,Zuhar,Asar,Magrib,Isha,Jamaat(A),Infiradi(B),Qaza(C),Pending(D)\n";
    for (var r in records) {
      csv += "${r['date']},${r['Fajar']},${r['Zuhar']},${r['Asar']},${r['Magrib']},${r['Isha']},${r['counts']['A']},${r['counts']['B']},${r['counts']['C']},${r['counts']['D']}\n";
    }
    return csv;
  }
}

// ---------------- AUTH SCREEN ----------------
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void handleLogin() {
    String email = _emailController.text.trim().toLowerCase();
    if (email.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainDashboardScreen(userEmail: email)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mosque, size: 70, color: Colors.teal),
                  const SizedBox(height: 10),
                  const Text(
                    'Namaz Tracker Login',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(),
                      hintText: 'example@gmail.com',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      minimumSize: const Size.fromHeight(45),
                    ),
                    child: const Text('Login', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- MAIN DASHBOARD ----------------
class MainDashboardScreen extends StatefulWidget {
  final String userEmail;
  const MainDashboardScreen({super.key, required this.userEmail});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DailyTrackerPage(userEmail: widget.userEmail),
      HistoryPage(userEmail: widget.userEmail),
      ReportsPage(userEmail: widget.userEmail),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Namaz Tracker'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
          )
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit_calendar), label: 'Tracker'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Namaz History'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Reports'),
        ],
      ),
    );
  }
}

// ---------------- DAILY TRACKER TAB ----------------
class DailyTrackerPage extends StatefulWidget {
  final String userEmail;
  const DailyTrackerPage({super.key, required this.userEmail});

  @override
  State<DailyTrackerPage> createState() => _DailyTrackerPageState();
}

class _DailyTrackerPageState extends State<DailyTrackerPage> {
  DateTime selectedDate = DateTime.now();

  Map<String, String> _todayStatus = {
    'Fajar': 'A', 'Zuhar': 'A', 'Asar': 'A', 'Magrib': 'A', 'Isha': 'A',
  };

  void _resetStatusToDefault() {
    setState(() {
      _todayStatus = {
        'Fajar': 'A', 'Zuhar': 'A', 'Asar': 'A', 'Magrib': 'A', 'Isha': 'A',
      };
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _resetStatusToDefault();
      });
    }
  }

  void _saveRecord() {
    int a = 0, b = 0, c = 0, d = 0;
    _todayStatus.forEach((_, val) {
      if (val == 'A') a++;
      if (val == 'B') b++;
      if (val == 'C') c++;
      if (val == 'D') d++;
    });

    String dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    UserDatabase.addOrUpdateRecord(widget.userEmail, {
      'date': dateStr,
      'dateTime': selectedDate,
      ..._todayStatus,
      'counts': {'A': a, 'B': b, 'C': c, 'D': d}
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Record saved for $dateStr!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('User: ${widget.userEmail}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey), overflow: TextOverflow.ellipsis),
              ),
              ElevatedButton.icon(
                onPressed: () => _selectDate(context),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(formattedDate),
              )
            ],
          ),
          const SizedBox(height: 10),
          const Text('Select Namaz Status:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: _todayStatus.keys.map((namaz) {
                return Card(
                  child: ListTile(
                    title: Text(namaz, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: DropdownButton<String>(
                      value: _todayStatus[namaz],
                      items: const [
                        DropdownMenuItem(value: 'A', child: Text('Jamaat (A)')),
                        DropdownMenuItem(value: 'B', child: Text('Infiradi (B)')),
                        DropdownMenuItem(value: 'C', child: Text('Qaza (C)')),
                        DropdownMenuItem(value: 'D', child: Text('Pending (D)')),
                      ],
                      onChanged: (val) => setState(() => _todayStatus[namaz] = val!),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          ElevatedButton(
            onPressed: _saveRecord,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, minimumSize: const Size.fromHeight(48)),
            child: const Text('Save Entry', style: TextStyle(color: Colors.white, fontSize: 16)),
          )
        ],
      ),
    );
  }
}

// ---------------- NAMAZ HISTORY TAB WITH EXPORT ----------------
class HistoryPage extends StatelessWidget {
  final String userEmail;
  const HistoryPage({super.key, required this.userEmail});

  void _exportCSV(BuildContext context) {
    String csvData = UserDatabase.generateCSV(userEmail);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Excel / CSV Data'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Copy CSV data below for Excel:'),
              const SizedBox(height: 10),
              SelectableText(
                csvData,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = UserDatabase.getRecords(userEmail);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Namaz History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _exportCSV(context),
                icon: const Icon(Icons.grid_on, size: 16),
                label: const Text('Export CSV'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: records.isEmpty
              ? const Center(child: Text('No records found. Please save an entry.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final rec = records[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today, color: Colors.teal),
                        title: Text(rec['date'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Fajar:${rec['Fajar']} | Zuhar:${rec['Zuhar']} | Asar:${rec['Asar']} | Magrib:${rec['Magrib']} | Isha:${rec['Isha']}"),
                        trailing: Text("A:${rec['counts']['A']} B:${rec['counts']['B']} C:${rec['counts']['C']} D:${rec['counts']['D']}"),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ---------------- REPORTS TAB ----------------
class ReportsPage extends StatefulWidget {
  final String userEmail;
  const ReportsPage({super.key, required this.userEmail});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _filter = 'Overall';
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  final List<String> monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context) {
    final records = UserDatabase.getRecords(widget.userEmail);

    List<Map<String, dynamic>> filteredRecords = records.where((r) {
      if (r['dateTime'] == null) return true;
      DateTime dt = r['dateTime'];

      if (_filter == 'Weekly') {
        return DateTime.now().difference(dt).inDays <= 7;
      } else if (_filter == 'Monthly') {
        return dt.year == selectedYear && dt.month == selectedMonth;
      } else if (_filter == 'Yearly') {
        return dt.year == selectedYear;
      }
      return true;
    }).toList();

    int totA = 0, totB = 0, totC = 0, totD = 0;
    for (var r in filteredRecords) {
      totA += (r['counts']['A'] as int);
      totB += (r['counts']['B'] as int);
      totC += (r['counts']['C'] as int);
      totD += (r['counts']['D'] as int);
    }
    int grandTotal = totA + totB + totC + totD;

    // 1900 se 2200 tak tamam 301 saal ka poora range
    List<int> availableYears = List.generate(301, (index) => 1900 + index);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['Weekly', 'Monthly', 'Yearly', 'Overall'].map((f) {
              return ChoiceChip(
                label: Text(f),
                selected: _filter == f,
                onSelected: (selected) {
                  if (selected) setState(() => _filter = f);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 15),

          if (_filter == 'Monthly') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton<int>(
                  value: selectedMonth,
                  items: List.generate(12, (index) {
                    return DropdownMenuItem(value: index + 1, child: Text(monthNames[index]));
                  }),
                  onChanged: (val) => setState(() => selectedMonth = val!),
                ),
                const SizedBox(width: 20),
                DropdownButton<int>(
                  value: selectedYear,
                  items: availableYears.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                  onChanged: (val) => setState(() => selectedYear = val!),
                ),
              ],
            ),
          ],

          if (_filter == 'Yearly') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Select Year: ', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<int>(
                  value: selectedYear,
                  items: availableYears.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                  onChanged: (val) => setState(() => selectedYear = val!),
                ),
              ],
            ),
          ],

          const SizedBox(height: 15),
          Card(
            color: Colors.teal.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    _filter == 'Monthly'
                        ? '${monthNames[selectedMonth - 1]} $selectedYear Summary'
                        : _filter == 'Yearly'
                            ? '$selectedYear Year Summary'
                            : '$_filter Summary',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text('Total Namaz Logged: $grandTotal', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statBox('A (Jamaat)', '$totA', Colors.green),
                      _statBox('B (Time)', '$totB', Colors.blue),
                      _statBox('C (Qaza)', '$totC', Colors.orange),
                      _statBox('D (Pending)', '$totD', Colors.red),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _statBox(String title, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }
}
