import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

class Todo {
  String? id;
  String? job;
  String? details;
  bool? done;

  Todo({
    this.id,
    this.job,
    this.details,
    this.done,});

  Todo.fromDocumentShapshot({DocumentSnapshot? documentSnapshot}) {
    if (documentSnapshot!.data()!=null) {
      id=documentSnapshot.id;
      job=(documentSnapshot.data() as Map<String, dynamic>)['job'] as String;
      details=(documentSnapshot.data() as Map<String, dynamic>)['details'] as String;
      done=(documentSnapshot.data() as Map<String, dynamic>)['done'] as bool;
    }
    else {
      id='';
      job='';
      details='';
      done=false;
    }
  }
}

class Auth {
  final FirebaseAuth auth;

  Auth({required this.auth});

  Stream<User?> get user=> auth.authStateChanges();

  Future<String?> createAccount({String? email, String? password}) async {
    try {
      await auth.createUserWithEmailAndPassword(email: email!.trim(), password: password!.trim());
      return 'Success';
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
    catch (e) {
      rethrow;
    }
  }

  Future<String?> signIn({String? email, String? password}) async {
    try {
      await auth.signInWithEmailAndPassword(email: email!.trim(), password: password!.trim());
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
    catch (e) {
      rethrow;
    }
  }

  Future<String?> signOut() async {
    try {
      await auth.signOut();
      return 'Success';
    } on FirebaseAuthException catch(e) {
      return e.message;
    }
    catch (e) {
      rethrow;
    }
  }
}

class Database {
  final FirebaseFirestore firestore;

  Database({required this.firestore});

  Stream<List<Todo>> streamTodos({required String uid}) {
    try {
      return firestore
          .collection('todos')
          .doc(uid)
          .collection('todos')
          .where('done', isEqualTo: false)
          .snapshots()
          .map((q) {
            final List<Todo> retVal=[];
            q.docs.forEach((element) {
              retVal.add(Todo.fromDocumentShapshot(documentSnapshot: element));
            });
            return retVal;
          });
    }
    catch (e) {
      rethrow;
    }
  }

  Future<void> addTodo({String? uid, String? job, String? details}) async {
    try {
      firestore
      .collection('todos')
      .doc(uid)
      .collection('todos')
      .doc()
      .set({'job':job, 'details':details, 'done':false});
    }
    catch (e) {
      rethrow;
    }
  }

  Future<void> updateTodo({String? uid, String? id, String? job, String? details}) async {
    try {
      firestore
      .collection('todos')
      .doc(uid)
      .collection('todos')
      .doc(id)
      .update({'job': job, 'details': details, 'done': false});
    }
    catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTodo({String? uid, String? id}) async {
    try {
      firestore
      .collection('todos')
      .doc(uid)
      .collection('todos')
      .doc(id)
      .delete();
    }
    catch (e) {
      rethrow;
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Todo Demo',
      theme: ThemeData.dark(),
      home: FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Error'),
              ),
            );
          }
          if (snapshot.connectionState==ConnectionState.done) {
            return First();
          }
          return Scaffold(
            body: Center(
              child: Text('Loading...'),
            ),
          );
        },
      ),
    );
  }
}

class First extends StatefulWidget {
  const First({super.key});

  @override
  State<First> createState() => _FirstState();
}

class _FirstState extends State<First> {

  final FirebaseAuth auth1=FirebaseAuth.instance;
  final FirebaseFirestore firestore1=FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: Auth(auth: auth1).user,
        builder: (context, snapshot) {
          if (snapshot.connectionState==ConnectionState.active) {
            if (snapshot.data?.email==null) {       //new user
              return Login(auth: auth1, firestore: firestore1,);
            }
            else                                   //existed user
              return Home(auth: auth1, firestore: firestore1,);
          }
          else {
            return Scaffold(
              body: Center(
                child: Text('Loading...'),
              ),
            );
          }
        }
    );
  }
}

class Login extends StatefulWidget {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  const Login({super.key,
               required this.auth,
               required this.firestore});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {

  final emailController=TextEditingController();
  final passwordController=TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: Builder(
            builder: (context) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(hintText: 'Email'),
                    controller: emailController,
                  ),
                  TextFormField(
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(hintText: 'Password'),
                    controller: passwordController,
                  ),
                  SizedBox(height: 20,),
                  ElevatedButton(
                    onPressed: () async {
                      final String? retVal=await Auth(auth: widget.auth).signIn(
                        email: emailController.text,
                        password: passwordController.text,
                      );
                      if (retVal=='Success') {
                        emailController.clear();
                        passwordController.clear();
                      }
                      else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(retVal!)));
                      }
                    },
                    child: Text('Sign In'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final String? retVal=await Auth(auth: widget.auth).createAccount(
                        email: emailController.text,
                        password: passwordController.text,
                      );
                      if (retVal=='Success') {
                        emailController.clear();
                        passwordController.clear();
                      }
                      else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(retVal!)));
                      }
                    },
                    child: Text('Create account'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  const Home({super.key,
              required this.auth,
              required this.firestore});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final todoController1=TextEditingController();
  final todoController2=TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Todo App v1'),
                     actions: [
                       IconButton(
                         onPressed: () {
                           Auth(auth: widget.auth).signOut();
                         },
                         icon: Icon(Icons.exit_to_app),
                       ),
                     ],),
      body: Column(
        children: [
          SizedBox(height: 20,),
          Text('Add todo job here', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
          Card(
            margin: EdgeInsets.all(20),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(child: TextFormField(controller: todoController1,),),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      if (todoController1.text.isNotEmpty) {
                        setState(() {
                          Database(firestore: widget.firestore).addTodo(uid: widget.auth.currentUser!.uid,
                                                                        job: todoController1.text.trim(),
                                                                        details: todoController2.text.trim(),);
                          todoController1.clear();
                          todoController2.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.all(20),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(child: TextFormField(controller: todoController2,),),
                  IconButton(
                    icon: Icon(Icons.note_alt_outlined),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20,),
          Text('Your todos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
          Expanded(
            child: StreamBuilder(
              stream: widget.firestore.collection('todos').doc(widget.auth.currentUser!.uid)
                      .collection('todos').where('done', isEqualTo: false).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState==ConnectionState.active) {
                  if (snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text("You don't have any unfinished todos"),
                    );
                  }
                  final List<Todo> retVal=[];
                  snapshot.data!.docs.forEach((element) {
                    retVal.add(Todo.fromDocumentShapshot(documentSnapshot: element));
                  });
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: ListTile(
                            title: Text(retVal[index].job!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
                            subtitle: Text(retVal[index].details!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
                            trailing: FittedBox(
                              child: Column(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context)=>editPage(firestore: widget.firestore,
                                                                                                             uid: widget.auth.currentUser!.uid,
                                                                                                             id: retVal[index].id,
                                                                                                             job: retVal[index].job,
                                                                                                             detail: retVal[index].details,
                                                                                                             )));
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () {
                                      Database(firestore: widget.firestore).deleteTodo(uid: widget.auth.currentUser!.uid,
                                                                                       id: retVal[index].id);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  );
                }
                else {
                  return Center(child: Text('Loading...'),);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class editPage extends StatefulWidget {
  final firestore;
  final uid;
  final id;
  final job;
  final detail;

  const editPage({super.key, required this.firestore,
                             required this.uid,
                             required this.id,
                             required this.job,
                             required this.detail});

  @override
  State<editPage> createState() => _editPageState();
}

class _editPageState extends State<editPage> {

  final formKey=GlobalKey<FormState>();
  late TextEditingController jobController;
  late TextEditingController detailController;
  String newJob='', newDetail='';

  @override
  void initState() {
    super.initState();
    jobController=TextEditingController(text: widget.job);
    detailController=TextEditingController(text: widget.detail);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Text('Edit job here', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
              SizedBox(height: 20,),
              TextFormField(
                controller: jobController,
                decoration: InputDecoration(labelText: 'Job'),
                validator: (v) {
                  newJob=v!;
                },
              ),
              TextFormField(
                controller: detailController,
                decoration: InputDecoration(labelText: 'Details'),
                validator: (v) {
                  newDetail=v!;
                },
              ),
              SizedBox(height: 20,),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    await Database(firestore: widget.firestore).updateTodo(uid: widget.uid,
                                                                           id: widget.id,
                                                                           job: jobController.text.trim(),
                                                                           details: detailController.text.trim());
                    Navigator.of(context).pop();
                  }
                },
                child: Text('Update', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),),
            ],
          ),
        ),
      ),
    );
  }
}
