import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
class IOWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    file_test1();
    file_test2();
    test3();
    print(getMessage());
    test5();
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("IO"),
        titleSpacing: 10,
      ),
      body: Center(
        child: new Text("1.txt create file")
      ),
    );
  }

    void file_test1() async {
    print("file_test1()");
      String dir = (await getApplicationDocumentsDirectory()).path;
      var file = File("$dir/l.txt");
      print("$dir/l.txt");
      IOSink sink;

      try {
        bool exists = await file.exists();
        if (!exists) {
          await file.create();
        }

         sink = file.openWrite();
        // 默认的写文件操作会覆盖原有内容；如果要追究内容，用 append 模式
        // sink = file.openWrite(mode: FileMode.append);

        // write() 的参数是一个 Object，他会执行 obj.toString() 把转换后
        // 的 String 写入文件
        sink.write('Hello, Dart');
        //调用 flush 后才会真的把数据写出去
        await sink.flush();
      } catch (e) {
        print(e);
      }finally{
        sink?.close();
      }
    }

  void file_test2() async {
    print("file_test2()");
    String dir = (await getApplicationDocumentsDirectory()).path;
    var file = File("$dir/l.txt");
    try {
      Stream<List<int>> stream = file.openRead();
      var lines = stream
      // 把内容用 utf-8 解码
          .transform(utf8.decoder)
      // 每次返回一行
          .transform(LineSplitter());
      await for (var line in lines) {
        print(line);
      }
    } catch (e) {
      print(e);
    }
  }
  void test3() {
    var point = Point(2, 12, 'Some point');
    var pointJson = json.encode(point);
    print('pointJson = $pointJson');

    // List, Map 都是支持的
    var points = [point, point];
    var pointsJson = json.encode(points);
    print('pointsJson = $pointsJson');
  }

  Future<String> getMessage() async {
    try {
      final response = await http.get('https://www.baid.com/');
      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (e) {
      print('getMessage: $e');
    }
    return null;
  }
}


class Point {
  int x;
  int y;
  String description;

  Point(this.x, this.y, this.description);
  // 注意，我们的方法只有一个语句，这个语句定义了一个 map。
  // 使用这种语法的时候，Dart 会自动把这个 map 当做方法的返回值
  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'desc': description
  };
  Point.fromJson(Map<String, dynamic> map)
      : x = map['x'], y = map['y'], description = map['desc'];

  // 为了方便后面演示，也加入一个 toString
  @override
  String toString() {
    return "Point{x=$x, y=$y, desc=$description}";
  }
}



class FlutterDemo extends StatefulWidget {
  FlutterDemo({Key key}) : super(key: key);

  @override
  _FlutterDemoState createState() => new _FlutterDemoState();
}

class _FlutterDemoState extends State<FlutterDemo> {
  int _counter;

  @override
  void initState() {
    super.initState();
    _readCounter().then((int value) {
      setState(() {
        _counter = value;
      });
    });
  }

  Future<File> _getLocalFile() async {
    // get the path to the document directory.
    String dir = (await getApplicationDocumentsDirectory()).path;
    print("$dir");
    return new File('$dir/counter.txt');
  }

  Future<int> _readCounter() async {
    try {
      File file = await _getLocalFile();
      // read the variable as a string from the file.
      String contents = await file.readAsString();
      return int.parse(contents);
    } on FileSystemException {
      return 0;
    }
  }

  Future<Null> _incrementCounter() async {
    setState(() {
      _counter++;
    });
    // write the variable as a string to the file
    await (await _getLocalFile()).writeAsString('$_counter');
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Flutter Demo')),
      body: new Center(
        child: new Text('Button tapped $_counter time${
            _counter == 1 ? '' : 's'
        }.'),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: new Icon(Icons.add),
      ),
    );
  }
}




class Todo {
  static const columnId = 'id';
  static const columnTitle = 'title';
  static const columnContent = 'content';

  int id;
  String title;
  String content;

  Todo(this.title, this.content, [this.id]);

  Todo.fromMap(Map<String, dynamic> map)
      : id = map[columnId], title = map[columnTitle], content = map[columnContent];

  Map<String, dynamic> toMap() => {
    columnTitle: title,
    columnContent: content,
  };

  @override
  String toString() {
    return 'Todo{id=$id, title=$title, content=$content}';
  }
}

void test5() async {
  const table = 'Todo';
  // getDatabasesPath() 的 sqflite 提供的函数
  var path = await getDatabasesPath() + '/demo.db';
  // 使用 openDatabase 打开数据库
  var database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        var sql ='''
            CREATE TABLE $table ('
            ${Todo.columnId} INTEGER PRIMARY KEY,'
            ${Todo.columnTitle} TEXT,'
            ${Todo.columnContent} TEXT'
            )
            ''';
        // execute 方法可以执行任意的 SQL
        print(sql);
        await db.execute(sql);
      }
  );
  // 为了让每次运行的结果都一样，先把数据清掉
  await database.delete(table);

  var todo1 = Todo('Flutter', 'Learn Flutter widgets.');
  var todo2 = Todo('Flutter', 'Learn how to to IO in Flutter.');

  // 插入数据
  await database.insert(table, todo1.toMap());
  await database.insert(table, todo2.toMap());

  List<Map> list = await database.query(table);
  // 重新赋值，这样 todo.id 才不会为 0
  todo1 = Todo.fromMap(list[0]);
  todo2 = Todo.fromMap(list[1]);
  print('query: todo1 = $todo1');
  print('query: todo2 = $todo2');

  todo1.content += ' Come on!';
  todo2.content += ' I\'m tired';
  // 使用事务
  await database.transaction((txn) async {
    // 注意，这里面只能用 txn。直接使用 database 将导致死锁
    await txn.update(table, todo1.toMap(),
        // where 的参数里，我们可以使用 ? 作为占位符，对应的值按顺序放在 whereArgs

        // 注意，whereArgs 的参数类型是 List，这里不能写成 todo1.id.toString()。
        // 不然就变成了用 String 和 int 比较，这样一来就匹配不到待更新的那一行了
        where: '${Todo.columnId} = ?', whereArgs: [todo1.id]);
    await txn.update(table, todo2.toMap(),
        where: '${Todo.columnId} = ?', whereArgs: [todo2.id]);
  });

  list = await database.query(table);
  for (var map in list) {
    var todo = Todo.fromMap(map);
    print('updated: todo = $todo');
  }

  // 最后，别忘了关闭数据库
  await database.close();
}