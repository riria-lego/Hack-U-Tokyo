import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(TimetableApp());
}

class Subject {
  String name;
  String day;
  TimeOfDay startTime;
  TimeOfDay endTime;

  Subject({
    required this.name,
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  // JSONへの変換メソッド
  Map<String, dynamic> toJson() => {
    'name': name,
    'day': day,
    'startTime': _timeOfDayToString(startTime),
    'endTime': _timeOfDayToString(endTime),
  };

  // JSONからの生成メソッド
  static Subject fromJson(Map<String, dynamic> json) => Subject(
    name: json['name'],
    day: json['day'],
    startTime: _stringToTimeOfDay(json['startTime']),
    endTime: _stringToTimeOfDay(json['endTime']),
  );

  static String _timeOfDayToString(TimeOfDay time) =>
      '${time.hour}:${time.minute}';

  static TimeOfDay _stringToTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
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

  // 曜日ごとの背景色マップ
  final Map<String, Color> dayColors = {
    'Monday': Colors.red[100]!,
    'Tuesday': Colors.orange[100]!,
    'Wednesday': Colors.yellow[100]!,
    'Thursday': Colors.green[100]!,
    'Friday': Colors.blue[100]!,
    'Saturday': Colors.purple[100]!,
    'Sunday': Colors.pink[100]!,
    'その他': Colors.grey[300]!,
  };

  @override
  void initState() {
    super.initState();
    _loadSubjects();  // データを読み込む
  }

  // 教科データを保存するメソッド
  Future<void> _saveSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final subjectList = subjects.map((subject) => subject.toJson()).toList();
    prefs.setString('subjects', jsonEncode(subjectList));
  }

  // 教科データを読み込むメソッド
  Future<void> _loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final subjectString = prefs.getString('subjects');
    if (subjectString != null) {
      final List<dynamic> subjectList = jsonDecode(subjectString);
      setState(() {
        subjects.clear();
        subjects.addAll(subjectList.map((json) => Subject.fromJson(json)).toList());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    subjects.sort((a, b) {
      int dayComparison = _getDayOrder(a.day).compareTo(_getDayOrder(b.day));
      if (dayComparison != 0) {
        return dayComparison;
      }
      return a.startTime.hour * 60 + a.startTime.minute - b.startTime.hour * 60 + b.startTime.minute;
    });

    Map<String, List<Subject>> subjectsByDay = {};
    for (var subject in subjects) {
      if (!subjectsByDay.containsKey(subject.day)) {
        subjectsByDay[subject.day] = [];
      }
      subjectsByDay[subject.day]!.add(subject);
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('- 板写の獄 -'),
      ),
      body: ListView(
        children: subjectsByDay.keys.map((day) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  day,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ...subjectsByDay[day]!.map((subject) {
                return Container(
                  color: dayColors[day], // 背景色を設定
                  child: ListTile(
                    title: Text(subject.name),
                    subtitle: Text(
                        '${subject.startTime.format(context)} - ${subject.endTime.format(context)}'),
                    onTap: () => _editSubject(context, subjects.indexOf(subject)),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          subjects.remove(subject);
                          _saveSubjects();  // 削除後に保存
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        }).toList(),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 30.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingActionButton(
              onPressed: () => _addSubject(context),
              child: Icon(Icons.add),
              tooltip: '教科を追加',
            ),
            FloatingActionButton(
              onPressed: _captureAndSaveImage,
              child: Icon(Icons.camera_alt),
              tooltip: '写真を撮る',
            ),
            FloatingActionButton(
              onPressed: _viewImages,
              child: Icon(Icons.photo_library),
              tooltip: '画像を見る',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addSubject(BuildContext context) async {
    String name = '';
    String day = 'Monday';
    TimeOfDay startTime = TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = TimeOfDay(hour: 10, minute: 0);

    final result = await showDialog<Subject>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('教科を追加'),
              content: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Column(
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
                          setState(() {
                            day = newValue!;
                          });
                        },
                        items: <String>[
                          'Monday',
                          'Tuesday',
                          'Wednesday',
                          'Thursday',
                          'Friday',
                          'Saturday',
                          'Sunday',
                          'その他'
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
                ),
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
                      final newSubject = Subject(
                          name: name,
                          day: day,
                          startTime: startTime,
                          endTime: endTime);
                      Navigator.of(context).pop(newSubject);
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('追加'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        subjects.add(result);
        _saveSubjects();  // 追加後に保存
      });
      _createSubjectFolder(result); // 教科フォルダを生成
    }
  }

  Future<void> _editSubject(BuildContext context, int index) async {
    String name = subjects[index].name;
    String day = subjects[index].day;
    TimeOfDay startTime = subjects[index].startTime;
    TimeOfDay endTime = subjects[index].endTime;

    final result = await showDialog<Subject>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      setState(() {
                        day = newValue!;
                      });
                    },
                    items: <String>[
                      'Monday',
                      'Tuesday',
                      'Wednesday',
                      'Thursday',
                      'Friday',
                      'Saturday',
                      'Sunday',
                      'その他'
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
                    child:
                    Text('開始時刻: ${startTime.format(context)}'),
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
                    final updatedSubject = Subject(
                        name: name,
                        day: day,
                        startTime: startTime,
                        endTime: endTime);
                    Navigator.of(context).pop(updatedSubject);
                  },
                  child: Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        subjects[index] = result;
        _saveSubjects();  // 更新後に保存
      });
      _createSubjectFolder(result); // フォルダ名が変わるかもしれないので、再作成
    }
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
              _isTimeWithinRange(
                  subject.startTime, subject.endTime, now),
          orElse: () => Subject(
              name: 'その他',
              day: 'その他',
              startTime: TimeOfDay.now(),
              endTime: TimeOfDay.now()),
        );

        final directory = await getApplicationDocumentsDirectory();
        final subjectDir =
        Directory('${directory.path}/${currentSubject.name}');
        if (!await subjectDir.exists()) {
          await subjectDir.create();
        }

        final String fileName =
            '${DateTime.now().millisecondsSinceEpoch}.png';
        final File newImage = File('${subjectDir.path}/$fileName');
        await newImage.writeAsBytes(await File(pickedFile.path).readAsBytes());

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('画像が保存されました')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('カメラおよびストレージのアクセスが許可されていません')),
      );
    }
  }

  Future<void> _viewImages() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeekdaySelectorScreen(
          subjects: subjects, // subjectsを渡す
          dayColors: dayColors,
        ),
      ),
    );
  }

  int _getDayOrder(String day) {
    switch (day) {
      case 'Monday':
        return 1;
      case 'Tuesday':
        return 2;
      case 'Wednesday':
        return 3;
      case 'Thursday':
        return 4;
      case 'Friday':
        return 5;
      case 'Saturday':
        return 6;
      case 'Sunday':
        return 7;
      case 'その他':
        return 8;
      default:
        return 9;
    }
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
        return 'その他';
    }
  }

  bool _isTimeWithinRange(
      TimeOfDay startTime, TimeOfDay endTime, DateTime now) {
    final nowTime = TimeOfDay(hour: now.hour, minute: now.minute);
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    final nowMinutes = nowTime.hour * 60 + nowTime.minute;
    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }

  Future<void> _createSubjectFolder(Subject subject) async {
    final directory = await getApplicationDocumentsDirectory();
    final subjectDir = Directory('${directory.path}/${subject.name}');
    if (!await subjectDir.exists()) {
      await subjectDir.create();
    }
  }
}

// WeekdaySelectorScreenクラスの定義
class WeekdaySelectorScreen extends StatelessWidget {
  final List<Subject> subjects;
  final Map<String, Color> dayColors;

  WeekdaySelectorScreen({required this.subjects, required this.dayColors});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('曜日を選択')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDayButton(context, 'Monday'),
          _buildDayButton(context, 'Tuesday'),
          _buildDayButton(context, 'Wednesday'),
          _buildDayButton(context, 'Thursday'),
          _buildDayButton(context, 'Friday'),
          _buildDayButton(context, 'Saturday'),
          _buildDayButton(context, 'Sunday'),
          _buildDayButton(context, 'その他'),
        ],
      ),
    );
  }

  Widget _buildDayButton(BuildContext context, String day) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: dayColors[day], // 背景色を設定
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                FolderListScreen(subjects: subjects, day: day), // subjectsを渡す
          ),
        );
      },
      child: Text(day),
    );
  }
}

// FolderListScreenクラスの定義
class FolderListScreen extends StatefulWidget {
  final List<Subject> subjects; // subjectsを受け取るように変更
  final String day;

  FolderListScreen({required this.subjects, required this.day});

  @override
  _FolderListScreenState createState() => _FolderListScreenState();
}

class _FolderListScreenState extends State<FolderListScreen> {
  List<Directory> subjectDirs = [];

  @override
  void initState() {
    super.initState();
    _loadSubjectDirectories(); // 非同期処理を初期化時に呼び出す
  }

  Future<void> _loadSubjectDirectories() async {
    final directory = Directory((await getApplicationDocumentsDirectory()).path);
    List<Directory> dirs = [];
    for (Subject subject in widget.subjects.where((subject) => subject.day == widget.day)) {
      Directory subjectDir = Directory('${directory.path}/${subject.name}');
      if (!await subjectDir.exists()) {
        await subjectDir.create();
      }
      dirs.add(subjectDir);
    }

    setState(() {
      subjectDirs = dirs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.day} のフォルダー')),
      body: ListView.builder(
        itemCount: subjectDirs.length,
        itemBuilder: (context, index) {
          final subjectDir = subjectDirs[index];
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
        },
      ),
    );
  }
}

// ImageListScreenクラスの定義
class ImageListScreen extends StatefulWidget {
  final Directory subjectDir;

  ImageListScreen({required this.subjectDir});

  @override
  _ImageListScreenState createState() => _ImageListScreenState();
}

class _ImageListScreenState extends State<ImageListScreen> {
  late List<FileSystemEntity> imageFiles;

  @override
  void initState() {
    super.initState();
    imageFiles = widget.subjectDir.listSync();
  }

  @override
  Widget build(BuildContext context) {
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
                    builder: (context) => ImageDetailScreen(
                      imageFile: imageFile,
                      onDelete: () {
                        setState(() {
                          imageFiles.removeAt(index);
                        });
                      },
                    ),
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

// ImageDetailScreenクラスの定義
class ImageDetailScreen extends StatelessWidget {
  final File imageFile;
  final VoidCallback onDelete;

  ImageDetailScreen({required this.imageFile, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('画像詳細'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () async {
              final directory = await getExternalStorageDirectory();
              final downloadPath =
                  '${directory!.path}/${imageFile.uri.pathSegments.last}';
              final File downloadFile = File(downloadPath);
              await downloadFile.writeAsBytes(await imageFile.readAsBytes());

              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('画像がダウンロードされました')));
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              await imageFile.delete();
              onDelete();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('画像が削除されました')));
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
