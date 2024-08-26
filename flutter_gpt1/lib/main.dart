import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(TimetableApp());
}

class Subject {
  String name;
  String day;
  TimeOfDay startTime;
  TimeOfDay endTime;

  Subject({required this.name, required this.day, required this.startTime, required this.endTime});
}

class TimetableApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TimetableScreen(),
    );
  }
}

class TimetableScreen extends StatefulWidget {
  @override
  _TimetableScreenState createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final List<Subject> subjects = [];
  final picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Timetable App'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return ListTile(
                  title: Text(subject.name),
                  subtitle: Text('${subject.day} ${subject.startTime.format(context)} - ${subject.endTime.format(context)}'),
                  onTap: () => _editSubject(context, index),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        subjects.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _addSubject(context),
                child: Text('教科を追加'),
              ),
              ElevatedButton(
                onPressed: _captureAndSaveImage,
                child: Text('写真を撮る'),
              ),
              ElevatedButton(
                onPressed: _viewImages,
                child: Text('画像を見る'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addSubject(BuildContext context) async {
    String name = '';
    String day = 'Monday';
    TimeOfDay startTime = TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = TimeOfDay(hour: 10, minute: 0);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('教科を追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: '教科名'),
                onChanged: (value) {
                  name = value;
                },
              ),
              DropdownButton<String>(
                value: day,
                onChanged: (String? newValue) {
                  day = newValue!;
                },
                items: <String>[
                  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                  );
                  if (pickedTime != null) {
                    setState(() {
                      startTime = pickedTime;
                    });
                  }
                },
                child: Text('開始時刻: ${startTime.format(context)}'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: endTime,
                  );
                  if (pickedTime != null) {
                    setState(() {
                      endTime = pickedTime;
                    });
                  }
                },
                child: Text('終了時刻: ${endTime.format(context)}'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                if (name.isNotEmpty) {
                  setState(() {
                    subjects.add(Subject(name: name, day: day, startTime: startTime, endTime: endTime));
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text('追加'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editSubject(BuildContext context, int index) async {
    String name = subjects[index].name;
    String day = subjects[index].day;
    TimeOfDay startTime = subjects[index].startTime;
    TimeOfDay endTime = subjects[index].endTime;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('教科を編集'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: '教科名'),
                onChanged: (value) {
                  name = value;
                },
                controller: TextEditingController(text: name),
              ),
              DropdownButton<String>(
                value: day,
                onChanged: (String? newValue) {
                  day = newValue!;
                },
                items: <String>[
                  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                  );
                  if (pickedTime != null) {
                    setState(() {
                      startTime = pickedTime;
                    });
                  }
                },
                child: Text('開始時刻: ${startTime.format(context)}'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: endTime,
                  );
                  if (pickedTime != null) {
                    setState(() {
                      endTime = pickedTime;
                    });
                  }
                },
                child: Text('終了時刻: ${endTime.format(context)}'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  subjects[index] = Subject(name: name, day: day, startTime: startTime, endTime: endTime);
                });
                Navigator.of(context).pop();
              },
              child: Text('保存'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _captureAndSaveImage() async {
    final statusCamera = await Permission.camera.request();
    final statusStorage = await Permission.storage.request();

    if (statusCamera.isGranted && statusStorage.isGranted) {
      final pickedFile = await picker.getImage(source: ImageSource.camera);

      if (pickedFile != null) {
        final now = DateTime.now();
        final currentSubject = subjects.firstWhere(
              (subject) =>
          subject.day == _getDayName(now.weekday) &&
              _isTimeWithinRange(subject.startTime, subject.endTime, now),
          orElse: () => Subject(name: 'その他', day: '', startTime: TimeOfDay.now(), endTime: TimeOfDay.now()),
        );

        final directory = await getApplicationDocumentsDirectory();
        final subjectDir = Directory('${directory.path}/${currentSubject.name}');
        if (!await subjectDir.exists()) {
          await subjectDir.create();
        }

        final String fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
        final File newImage = File('${subjectDir.path}/$fileName');
        await newImage.writeAsBytes(await File(pickedFile.path).readAsBytes());

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('画像が保存されました')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('カメラおよびストレージのアクセスが許可されていません')),
      );
    }
  }

  Future<void> _viewImages() async {
    final directory = await getApplicationDocumentsDirectory();
    final subjectDirs = Directory(directory.path).listSync();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectListScreen(subjectDirs: subjectDirs),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  bool _isTimeWithinRange(TimeOfDay startTime, TimeOfDay endTime, DateTime now) {
    final nowTime = TimeOfDay(hour: now.hour, minute: now.minute);
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    final nowMinutes = nowTime.hour * 60 + nowTime.minute;
    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }
}

class SubjectListScreen extends StatelessWidget {
  final List<FileSystemEntity> subjectDirs;

  SubjectListScreen({required this.subjectDirs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('保存された画像'),
      ),
      body: ListView.builder(
        itemCount: subjectDirs.length,
        itemBuilder: (context, index) {
          final subjectDir = subjectDirs[index];
          if (subjectDir is Directory) {
            return ListTile(
              title: Text(subjectDir.path.split('/').last),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageListScreen(subjectDir: subjectDir),
                  ),
                );
              },
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }
}

class ImageListScreen extends StatelessWidget {
  final Directory subjectDir;

  ImageListScreen({required this.subjectDir});

  @override
  Widget build(BuildContext context) {
    final imageFiles = subjectDir.listSync();

    return Scaffold(
      appBar: AppBar(
        title: Text('画像一覧'),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemCount: imageFiles.length,
        itemBuilder: (context, index) {
          final imageFile = imageFiles[index];
          if (imageFile is File) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageDetailScreen(imageFile: imageFile),
                  ),
                );
              },
              child: Image.file(imageFile),
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }
}

class ImageDetailScreen extends StatelessWidget {
  final File imageFile;

  ImageDetailScreen({required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('画像の詳細'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () async {
              final directory = await getExternalStorageDirectory();
              final path = '${directory!.path}/${imageFile.path.split('/').last}';
              final File newImage = await imageFile.copy(path);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('画像がダウンロードされました: $path')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Image.file(imageFile),
      ),
    );
  }
}
