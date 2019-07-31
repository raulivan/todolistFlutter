import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

void main() {
  runApp(new MaterialApp(
    home: new Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _itemController = new TextEditingController();

  List _todoList = [];
  Map<String, dynamic> _ultimoElementoRemovido;
  int _indiceUltimoElementoRemovido;

  //Metodo chamando sempre que é executado
  @override
  void initState() {
    super.initState();
    _lerArquivo().then((onValue) {
      setState(() {
        _todoList = jsonDecode(onValue);
      });
    });
  }

  void adicionar() {
    setState(() {
      Map<String, dynamic> novoItem = new Map();
      novoItem["title"] = _itemController.text;
      _itemController.text = '';
      novoItem["ok"] = false;
      _todoList.add(novoItem);
      _salvarArquivo();
    });
  }

  Future<Null> _aoAtualizar() async{
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _todoList.sort((a,b){
      if(a["ok"] && !b["ok"])
        return 1;
      else if(!a["ok"] && b["ok"])
        return -1;
      else
        return 0;
    });

    _salvarArquivo();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TLA - Todo List'),
        backgroundColor: Colors.blueAccent,
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
                        labelText: 'Nova tarefa',
                        labelStyle: TextStyle(color: Colors.blue)),
                    controller: _itemController,
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text('Add'),
                  textColor: Colors.white,
                  onPressed: adicionar,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _aoAtualizar,
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10),
                itemCount: _todoList.length,
                itemBuilder: construtorItens),
            )
          )
        ],
      ),
    );
  }

  Widget construtorItens(context, index) {
    //return ListTile(title: Text(_todoList[index]),);
    //Permite deslizar o item
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_todoList[index]["title"]),
        value: _todoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon((_todoList[index]["ok"] ? Icons.check : Icons.error)),
        ),
        onChanged: (checked) {
          setState(() {
            _todoList[index]["ok"] = checked;
            _salvarArquivo();
          });
        },
      ),
      onDismissed: (direcao) {
        setState(() {
          _ultimoElementoRemovido = Map.from(_todoList[index]);
          _indiceUltimoElementoRemovido = index;
          _todoList.removeAt(index);

          _salvarArquivo();

          final alerta = SnackBar(
            content: Text(
                'Tarefa \"${_ultimoElementoRemovido['title']}\" removida com sucesso!'),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () {
                setState(() {
                  _todoList.insert(
                      _indiceUltimoElementoRemovido, _ultimoElementoRemovido);
                      _salvarArquivo();
                });
              },
            ),
            duration: Duration(seconds: 2),
          );
          
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(alerta);
        });
      },
    );
  }

  Future<File> _getArquivo() async {
    final diretorio = getApplicationDocumentsDirectory();
    return new File('$diretorio/todo_db.json');
  }

  Future<File> _salvarArquivo() async {
    String dados = json.encode(_todoList);
    final arquivo = await _getArquivo();
    return arquivo.writeAsString(dados);
  }

  Future<String> _lerArquivo() async {
    try {
      final arquivo = await _getArquivo();
      return arquivo.readAsString();
    } catch (ex) {
      return null;
    }
  }
}
