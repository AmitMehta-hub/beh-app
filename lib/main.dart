import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const BEHQMSApp());
}

class BEHQMSApp extends StatelessWidget {
  const BEHQMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BEH Quality & Incident Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0A192F), // Navy Blue
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A192F),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A192F),
          secondary: const Color(0xFFFFB800), // Amber / Yellow accent
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

// Data Model
class Ticket {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final String priority;
  String status;
  final DateTime reportedDate;
  final DateTime targetDate;
  final String reporterName;
  final List<String> photos;
  String? completionNotes;
  String? rejectionReason;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.priority,
    required this.status,
    required this.reportedDate,
    required this.targetDate,
    required this.reporterName,
    this.photos = const [],
    this.completionNotes,
    this.rejectionReason,
  });

  bool get isOverdue =>
      DateTime.now().isAfter(targetDate) && status != 'CLOSED';
}

// Global Demo State
List<Ticket> demoTickets = [
  Ticket(
    id: 'BEH-QMS-2026-00001',
    title: 'OT 2 Microscope Light Malfunction',
    description: 'Main halogen light source flickering intermittently during surgery.',
    category: 'Maintenance & Biomedical Equipment',
    location: 'Operation Theatre 2',
    priority: 'CRITICAL',
    status: 'COMPLETED - AWAITING VERIFICATION',
    reportedDate: DateTime.now().subtract(const Duration(hours: 5)),
    targetDate: DateTime.now().add(const Duration(hours: 1)),
    reporterName: 'Sunita Shrestha (Staff Nurse)',
    completionNotes: 'Replaced faulty power transformer and tested illumination.',
  ),
  Ticket(
    id: 'BEH-QMS-2026-00002',
    title: 'Water Leakage Near Patient Waiting Area',
    description: 'Ceiling pipe leaking water on the floor, potential slip hazard.',
    category: 'Electrical & Plumbing',
    location: 'OPD Block A',
    priority: 'HIGH',
    status: 'UNDER PROCESS',
    reportedDate: DateTime.now().subtract(const Duration(days: 1)),
    targetDate: DateTime.now().subtract(const Duration(hours: 2)), // Overdue
    reporterName: 'Rabin Thapa (Housekeeping)',
  ),
];

// --- 1. DASHBOARD SCREEN ---
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    int openCount = demoTickets.where((t) => t.status != 'CLOSED').length;
    int awaitingVerification =
        demoTickets.where((t) => t.status == 'COMPLETED - AWAITING VERIFICATION').length;
    int overdueCount = demoTickets.where((t) => t.isOverdue).length;

    List<Ticket> filtered = demoTickets.where((t) {
      if (selectedFilter == 'OVERDUE') return t.isOverdue;
      if (selectedFilter == 'VERIFY') {
        return t.status == 'COMPLETED - AWAITING VERIFICATION';
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BIRATNAGAR EYE HOSPITAL',
                style: TextStyle(fontSize: 12, letterSpacing: 1.1, color: Color(0xFFFFB800))),
            Text('Quality & Incident System',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Metrics Cards
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                _buildMetricCard('Active Issues', openCount.toString(), Colors.blue.shade900),
                _buildMetricCard('Awaiting Verification', awaitingVerification.toString(), const Color(0xFFD97706)),
                _buildMetricCard('Overdue SLA', overdueCount.toString(), Colors.red.shade700),
              ],
            ),
          ),
          const Divider(height: 1),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All Reports'),
                const SizedBox(width: 8),
                _buildFilterChip('VERIFY', 'Needs Verification'),
                const SizedBox(width: 8),
                _buildFilterChip('OVERDUE', 'Overdue'),
              ],
            ),
          ),

          // Ticket List
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final ticket = filtered[index];
                return TicketCard(
                  ticket: ticket,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TicketDetailScreen(ticket: ticket),
                      ),
                    );
                    setState(() {});
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0A192F),
        foregroundColor: const Color(0xFFFFB800),
        icon: const Icon(Icons.add_a_photo),
        label: const Text('+ REPORT NEW ISSUE', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final newTicket = await Navigator.push<Ticket>(
            context,
            MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
          );
          if (newTicket != null) {
            setState(() {
              demoTickets.insert(0, newTicket);
            });
          }
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String count, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF0A192F),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 12),
      onSelected: (_) => setState(() => selectedFilter = key),
    );
  }
}

// --- 2. REPORT ISSUE SCREEN ---
class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  String _category = 'Patient Safety Incident';
  String _priority = 'MEDIUM';
  final List<String> _imagePaths = [];

  final List<String> _categories = [
    'Patient Safety Incident',
    'Clinical Issue',
    'Maintenance & Biomedical Equipment',
    'Administration',
    'Housekeeping & Cleaning',
    'Infection Prevention & Control',
    'Information Technology (IT)',
    'Electrical & Plumbing',
    'Security & Safety',
  ];

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() => _imagePaths.add(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Incident / Request')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title / Brief Issue *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Title is mandatory' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => _category = val!),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location / Department Occurred *',
                border: OutlineInputBorder(),
                hintText: 'e.g., OT 1, Ward B, OPD Counter',
              ),
              validator: (v) => v!.isEmpty ? 'Location is mandatory' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Severity / Urgency', border: OutlineInputBorder()),
              items: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (val) => setState(() => _priority = val!),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Detailed Description *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Description is mandatory' : null,
            ),
            const SizedBox(height: 16),
            const Text('Photographs (Evidence):', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ..._imagePaths.map((p) => SizedBox(
                      width: 70,
                      height: 70,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(p), fit: BoxFit.cover),
                      ),
                    )),
                InkWell(
                  onTap: () => _showPhotoSourceDialog(),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_a_photo, color: Color(0xFF0A192F)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A192F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final ticketId = 'BEH-QMS-2026-${(demoTickets.length + 1).toString().padLeft(5, '0')}';
                  final newTicket = Ticket(
                    id: ticketId,
                    title: _titleController.text,
                    description: _descController.text,
                    category: _category,
                    location: _locationController.text,
                    priority: _priority,
                    status: 'OPEN',
                    reportedDate: DateTime.now(),
                    targetDate: DateTime.now().add(const Duration(hours: 6)),
                    reporterName: 'Logged-in Staff Member',
                    photos: _imagePaths,
                  );
                  Navigator.pop(context, newTicket);
                }
              },
              child: const Text('SUBMIT REPORT', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  void _showPhotoSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Capture with Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Select from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- 3. TICKET DETAIL & VERIFICATION ---
class TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;
  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    return Scaffold(
      appBar: AppBar(title: Text(t.id)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (t.isOverdue)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade900),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('OVERDUE: Task passed target resolution date (${DateFormat('d MMM, hh:mm a').format(t.targetDate)}).',
                        style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 13)),
                  )
                ],
              ),
            ),
          Text(t.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A192F))),
          const SizedBox(height: 8),
          Row(
            children: [
              _statusBadge(t.status),
              const SizedBox(width: 8),
              _priorityBadge(t.priority),
            ],
          ),
          const Divider(height: 28),
          _detailRow('Location / Ward', t.location),
          _detailRow('Category', t.category),
          _detailRow('Reported By', t.reporterName),
          _detailRow('Reported On', DateFormat('d MMM yyyy, hh:mm a').format(t.reportedDate)),
          _detailRow('Target SLA', DateFormat('d MMM yyyy, hh:mm a').format(t.targetDate)),
          const SizedBox(height: 12),
          const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(t.description, style: const TextStyle(fontSize: 14)),
          if (t.completionNotes != null) ...[
            const Divider(height: 28),
            const Text('Action Taken by Department:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 4),
            Text(t.completionNotes!, style: const TextStyle(fontSize: 14)),
          ],
          const SizedBox(height: 24),

          // Mandatory Reporter Verification Block
          if (t.status == 'COMPLETED - AWAITING VERIFICATION')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E6),
                border: Border.all(color: const Color(0xFFFFB800), width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mandatory Reporter Closure Approval',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A192F))),
                  const SizedBox(height: 6),
                  const Text('Confirm whether this issue is genuinely resolved before closing.',
                      style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text('APPROVE & CLOSE'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800),
                          onPressed: () {
                            setState(() => t.status = 'CLOSED');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ticket officially verified and closed.')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text('REJECT', style: TextStyle(color: Colors.red)),
                          onPressed: () => _showRejectDialog(t),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showRejectDialog(Ticket t) {
    String reason = '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('State Reason for Reopening'),
        content: TextField(
          onChanged: (v) => reason = v,
          decoration: const InputDecoration(hintText: 'e.g., Still flickering under load'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                t.status = 'REOPENED';
                t.rejectionReason = reason;
              });
              Navigator.pop(context);
            },
            child: const Text('Reopen Ticket'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.blue;
    if (status == 'CLOSED') color = Colors.green;
    if (status == 'COMPLETED - AWAITING VERIFICATION') color = Colors.orange;
    if (status == 'REOPENED') color = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _priorityBadge(String priority) {
    Color color = Colors.grey;
    if (priority == 'CRITICAL') color = Colors.red;
    if (priority == 'HIGH') color = Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(priority, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

// Card Widget in Dashboard
class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;

  const TicketCard({super.key, required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      child: ListTile(
        onTap: onTap,
        title: Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${ticket.id} • ${ticket.location}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(ticket.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: ticket.status == 'CLOSED' ? Colors.green : Colors.blue.shade800,
                    )),
                if (ticket.isOverdue) ...[
                  const SizedBox(width: 8),
                  const Text('• OVERDUE', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                ]
              ],
            )
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
