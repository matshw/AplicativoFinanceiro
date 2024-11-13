import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalInfoScreen extends StatefulWidget {
  @override
  _PersonalInfoScreenState createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _genderController = TextEditingController();
  final _professionController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isEditing = false;
  String _selectedGender = "Homem";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        if (doc.data()!.containsKey('name')) {
          setState(() {
            _nameController.text = doc['name'];
          });
        } else {
          setState(() {
            _nameController.text = 'Nome não definido';
          });
        }

        if (doc.data()!.containsKey('dateOfBirth')) {
          _dateOfBirthController.text = doc['dateOfBirth'] ?? '';
        }
        if (doc.data()!.containsKey('gender')) {
          _genderController.text = doc['gender'] ?? '';
        }
        if (doc.data()!.containsKey('profession')) {
          _professionController.text = doc['profession'] ?? '';
        }
        if (doc.data()!.containsKey('phone')) {
          _phoneController.text = doc['phone'] ?? '';
        }
      } else {
        setState(() {
          _nameController.text = 'Nome não definido';
          _dateOfBirthController.text = '';
          _genderController.text = '';
          _professionController.text = '';
          _phoneController.text = '';
        });
      }
    }
  }

  Future<void> _saveUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'name': _nameController.text,
        'dateOfBirth': _dateOfBirthController.text,
        'gender': _selectedGender,
        'profession': _professionController.text,
        'phone': _phoneController.text,
      }, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
    prefs.setString('userName', _nameController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Informações salvas com sucesso!')),
      );

      Navigator.pop(context, _nameController.text);

      setState(() {
        _isEditing = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    if (_dateOfBirthController.text.isNotEmpty) {
      initialDate = DateFormat('yyyy-MM-dd').parse(_dateOfBirthController.text);
    }

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _dateOfBirthController.text =
            DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text(
          'Informações Pessoais',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (_isEditing) ...[
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Nome ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Rubik',
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _nameController,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Data de Nascimento',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Rubik',
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _dateOfBirthController,
                            keyboardType: TextInputType.datetime,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Gênero',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Rubik',
                          ),
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedGender = newValue!;
                          });
                        },
                        items: <String>['Homem', 'Mulher', 'Prefiro não dizer']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Telefone',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Rubik',
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Profissão',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Rubik',
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _professionController,
                      ),
                      SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 10.0),
                        child: ElevatedButton(
                          onPressed: _saveUserData,
                          child: Text(
                            'Salvar',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.tertiary,
                            elevation: 10,
                            fixedSize: Size.fromHeight(50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  'Nome',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 16,
                    fontFamily: 'Rubik',
                  ),
                ),
                Text(
                  _nameController.text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontFamily: 'Rubik',
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Data de Nascimento ',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 16,
                    fontFamily: 'Rubik',
                  ),
                ),
                Text(
                  _dateOfBirthController.text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontFamily: 'Rubik',
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Gênero ',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 16,
                    fontFamily: 'Rubik',
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Text(
                  _selectedGender,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontFamily: 'Rubik',
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Profissão',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 16,
                    fontFamily: 'Rubik',
                  ),
                ),
                Text(
                  _professionController.text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontFamily: 'Rubik',
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Telefone',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 16,
                    fontFamily: 'Rubik',
                  ),
                ),
                Text(
                  _phoneController.text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontFamily: 'Rubik',
                  ),
                ),
                SizedBox(height: 20),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
