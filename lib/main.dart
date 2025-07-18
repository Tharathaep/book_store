import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ระบบบันทึกร้านหนังสือ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const BookStoreScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BookStoreScreen extends StatefulWidget {
  const BookStoreScreen({super.key});

  @override
  State<BookStoreScreen> createState() => _BookStoreScreenState();
}

class _BookStoreScreenState extends State<BookStoreScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _volumeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
  String? _editingDocId;

  Future<void> _saveBook() async {
    try {
      final bookData = {
        'title': _titleController.text,
        'volume': int.tryParse(_volumeController.text) ?? 1,
        'purchaseLocation': _locationController.text,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (_editingDocId != null) {
        await _firestore.collection('books').doc(_editingDocId).update(bookData);
      } else {
        await _firestore.collection('books').add(bookData);
      }

      _clearForm();
      _editingDocId = null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editingDocId != null ? 'อัปเดตหนังสือเรียบร้อยแล้ว!' : 'บันทึกหนังสือเรียบร้อยแล้ว!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearForm() {
    _titleController.clear();
    _volumeController.clear();
    _locationController.clear();
    _priceController.clear();
  }

  void _editBook(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    setState(() {
      _editingDocId = document.id;
      _titleController.text = data['title'];
      _volumeController.text = data['volume'].toString();
      _locationController.text = data['purchaseLocation'];
      _priceController.text = data['price'].toString();
    });
    // Scroll to the form
    Scrollable.ensureVisible(
      context,
      alignment: 0,
      duration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _deleteBook(String docId) async {
    try {
      await _firestore.collection('books').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลบหนังสือเรียบร้อยแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ระบบบันทึกร้านหนังสือ'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.lightBlue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      _editingDocId != null ? 'แก้ไขหนังสือ' : 'เพิ่มหนังสือใหม่',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อหนังสือ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.book),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _volumeController,
                      decoration: const InputDecoration(
                        labelText: 'เล่มที่',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.format_list_numbered),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'ซื้อที่',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'ราคาที่ซื้อ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveBook,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: _editingDocId != null 
                                  ? Colors.orange 
                                  : Colors.blue,
                            ),
                            child: Text(
                              _editingDocId != null ? 'อัปเดตข้อมูล' : 'บันทึกข้อมูล',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        if (_editingDocId != null) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _clearForm();
                                setState(() {
                                  _editingDocId = null;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                backgroundColor: Colors.grey,
                              ),
                              child: const Text(
                                'ยกเลิก',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'รายการหนังสือ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('books')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'ยังไม่มีหนังสือในรายการ',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var document = snapshot.data!.docs[index];
                      var data = document.data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              data['volume'].toString(),
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ),
                          title: Text(
                            data['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('ซื้อที่: ${data['purchaseLocation']}'),
                              Text('ราคา: ${_currencyFormat.format(data['price'])}'),
                              if (data['timestamp'] != null)
                                Text(
                                  'วันที่บันทึก: ${DateFormat('dd/MM/yyyy HH:mm').format(data['timestamp'].toDate())}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editBook(document),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteBook(document.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _volumeController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}