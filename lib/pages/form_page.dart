import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../api/api_service.dart';
import '../model/cs.dart';

class FormPage extends StatefulWidget {
  final CusServ? rep;

  const FormPage({super.key, this.rep});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleIssues = TextEditingController();
  final TextEditingController _descriptionIssues = TextEditingController();

  double _rating = 1;
  int _idDivisionTarget = 1;
  int _idPriority = 1;
  File? _imageFile;
  bool _isLoading = false;

  final Map<int, String> _divisionOptions = {
    1: 'Billing',
    2: 'Tech',
    3: 'OPS',
    4: 'Sales',
  };

  final Map<int, String> _priorityOptions = {
    1: 'Critical',
    2: 'High',
    3: 'Medium',
    4: 'Low',
  };

  @override
  void initState() {
    super.initState();
    if (widget.rep != null) {
      _titleIssues.text = widget.rep!.titleIssues;
      _descriptionIssues.text = widget.rep!.descriptionIssues;
      _rating = double.tryParse(widget.rep!.rating) ?? 1;
      _idDivisionTarget = int.tryParse(widget.rep!.idDivisionTarget) ?? 1;
      _idPriority = int.tryParse(widget.rep!.idPriority) ?? 1;
      // Gambar tidak bisa langsung di-load dari URL ke File, jadi dilewati
    }
  }

  @override
  void dispose() {
    _titleIssues.dispose();
    _descriptionIssues.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70, // Kompres gambar untuk upload lebih cepat
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showImageOptions() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_imageFile != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                onTap: () {
                  setState(() {
                    _imageFile = null;
                  });
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showConfirmationDialog() async {
    if (!_formKey.currentState!.validate()) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please confirm the details:'),
            const SizedBox(height: 8),
            Text('Title: ${_titleIssues.text}'),
            Text('Division: ${_divisionOptions[_idDivisionTarget]}'),
            Text('Priority: ${_priorityOptions[_idPriority]}'),
            Text('Rating: $_rating / 5'),
            if (_imageFile != null) const Text('Image: Attached'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _submit();
            },
            child: const Text('Confirm & Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final report = CusServ(
        idCustomerService: widget.rep?.idCustomerService ?? '0',
        nim: widget.rep?.nim ?? '',
        titleIssues: _titleIssues.text.trim(),
        descriptionIssues: _descriptionIssues.text.trim(),
        rating: _rating.toString(),
        imageUrl: _imageFile?.path ?? '',
        idDivisionTarget: _idDivisionTarget.toString(),
        idPriority: _idPriority.toString(),
        divisionDepartmentName: _divisionOptions[_idDivisionTarget] ?? '',
        priorityName: _priorityOptions[_idPriority] ?? '',
      );

      File? imageFile = _imageFile;

      if (widget.rep == null) {
        await ApiService.createReport(report, imageFile);
      } else {
        await ApiService.updateReport(widget.rep!.nim, report, imageFile);
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.rep == null
                ? 'Report created successfully'
                : 'Report updated successfully',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildImagePreview() {
    if (_imageFile == null) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 50, color: Colors.grey),
              SizedBox(height: 8),
              Text('No image selected', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    } else {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            fit: BoxFit.cover,
            image: FileImage(_imageFile!),
          ),
        ),
        child: Align(
          alignment: Alignment.topRight,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _imageFile = null;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(4),
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.rep == null ? 'Create Report' : 'Edit Report'),
          centerTitle: true,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image preview section
                        const Text(
                          'Supporting Image',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildImagePreview(),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _showImageOptions,
                          icon: const Icon(Icons.add_a_photo),
                          label: Text(_imageFile == null ? 'Add Image' : 'Change Image'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 45),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        
                        // Report details section
                        const Text(
                          'Report Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titleIssues,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.title),
                          ),
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Please enter a title'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionIssues,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.description),
                          ),
                          textInputAction: TextInputAction.newline,
                          maxLines: 5,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Please enter a description'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        
                        // Division and Priority section
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _idDivisionTarget,
                                decoration: InputDecoration(
                                  labelText: 'Division',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                ),
                                items: _divisionOptions.entries
                                    .map(
                                      (entry) => DropdownMenuItem(
                                        value: entry.key,
                                        child: Text(entry.value),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _idDivisionTarget = value);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _idPriority,
                                decoration: InputDecoration(
                                  labelText: 'Priority',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                ),
                                items: _priorityOptions.entries
                                    .map(
                                      (entry) => DropdownMenuItem(
                                        value: entry.key,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.circle,
                                              size: 12,
                                              color: entry.key == 1
                                                  ? Colors.red
                                                  : entry.key == 2
                                                      ? Colors.orange
                                                      : entry.key == 3
                                                          ? Colors.yellow
                                                          : Colors.green,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(entry.value),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _idPriority = value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Rating section
                        const Text(
                          'How would you rate the severity?',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: RatingBar.builder(
                            initialRating: _rating,
                            minRating: 1,
                            direction: Axis.horizontal,
                            allowHalfRating: false,
                            itemCount: 5,
                            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                            itemBuilder: (context, _) => Icon(
                              Icons.star,
                              color: _idPriority == 1 ? Colors.red : Colors.amber,
                            ),
                            onRatingUpdate: (rating) {
                              setState(() {
                                _rating = rating;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            _getRatingText(),
                            style: TextStyle(
                              color: _rating >= 4
                                  ? Colors.red
                                  : _rating >= 3
                                      ? Colors.orange
                                      : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Submit button
                        ElevatedButton(
                          onPressed: _showConfirmationDialog,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            widget.rep == null ? 'Submit Report' : 'Update Report',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
  
  String _getRatingText() {
    if (_rating >= 5) return 'Extremely Severe';
    if (_rating >= 4) return 'Very Severe';
    if (_rating >= 3) return 'Moderately Severe';
    if (_rating >= 2) return 'Slightly Severe';
    return 'Not Severe';
  }
}