import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List _toDoList = [];
  final _textController = TextEditingController();

  Map<String,dynamic> _lastRemoved;
  int _lastRemovedIndex;

  Future<Null> _refresh()async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {  
      _toDoList.sort(
        (a,b){
          if(a["ok"]&&!b["ok"]) return 1;
          else if(!a["ok"]&&b["ok"]) return -1;
          else return 0;
        }
      );
      _saveData();
    });

    return null;
  }

  @override
  void initState(){
    super.initState();
    _readData().then((data){
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo(){
    setState(() {
      Map<String,dynamic> newToDo = Map();
      newToDo["title"] = _textController.text;
      _textController.text = "";
      newToDo["ok"] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();

    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      throw (e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de tarefas"),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Nova tarefa",
                      labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                    controller: _textController,
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
                child: ListView.builder(
                padding: EdgeInsets.only(top: 10),
                itemBuilder: buildListTile,
                itemCount: _toDoList.length,
              ),
              onRefresh: _refresh,
            )
          )
        ],
      ),
    );
  }

  Widget buildListTile(context, index){
    
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(Icons.delete, color: Colors.white)
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        activeColor: Colors.blue,
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"]?Icons.check:Icons.error),
        ), 
        onChanged: (c) {
          setState(() {
            _toDoList[index]["ok"] = c;
            _saveData();
          });
        },    
      ), 
      onDismissed: (direction){
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedIndex = index;
          _toDoList.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
            action: SnackBarAction(label:"Desfazer", onPressed: (){
              setState(() {
                _toDoList.insert(_lastRemovedIndex, _lastRemoved);
                _saveData();
              });
            }),
            duration: Duration(seconds:2),
          );

          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }


}
