import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pretty_json/pretty_json.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';

String _SERVICES = '''
  query Services {
    services {
      items{
        id
      }
    }
  }
''';

class AppSync extends StatefulWidget {
  AppSync({Key key}) : super(key: key);

  @override
  _AppSyncState createState() => _AppSyncState();
}

class _AppSyncState extends State<AppSync> {
  SharedPreferences _prefs;
  ValueNotifier<GraphQLClient> client;
  final _userService = UserService(userPool);
  User _user = User();
  CognitoUser _cognitoUser;
  CognitoUserPool _userPool;
  CognitoUserSession _session;
  String _token;

  Future<UserService> _getValues() async {
    await _userService.init();
    _cognitoUser = await _userPool.getCurrentUser();
    _session = await _cognitoUser.getSession();
    _token = _session.getAccessToken().getJwtToken();
    print('TOKEN:'+_token);
    return _userService;
  }

  @override
  void initState() {
    super.initState();

    final httpLink = HttpLink(
      uri:
          'https://4mlhocrou5dexcuwwp766qvoae.appsync-api.ap-southeast-1.amazonaws.com',
    );
   
    Link link = httpLink;

    // final token = _prefs.getString("myToken");
    print(_token);
    var authLink = AuthLink(
      getToken: () async => _token,
    );

    link = httpLink.concat(authLink);

    client = ValueNotifier(
      GraphQLClient(
        cache: InMemoryCache(),
        link: link,
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getValues(),
        builder: (context, AsyncSnapshot<UserService> snapshot) {
          return GraphQLProvider(
            client: client,
            child: Scaffold(
                appBar: AppBar(title: Text('Loading...')),
                body: Container(
                  child: Query(
                    options: QueryOptions(
                      documentNode: gql(_SERVICES),
                    ),
                    builder: (
                      QueryResult result, {
                      Refetch refetch,
                      FetchMore fetchMore,
                    }) {
                      if (result.hasException) {
                        return Text(result.exception.toString());
                      }

                      if (result.loading && result.data == null) {
                        return const Center(
                          child: SizedBox(
                            height: 200.0,
                            width: 200.0,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                              backgroundColor: Color(0xff2CB9B0),
                            ),
                          ),
                        );
                      }

                      // final myData = result.data['courses'];

                      final myData =
                          result.data['services'] as List<dynamic>;
                      return Column(
                        children: <Widget>[
                          Expanded(
                            child: ListView.builder(
                                scrollDirection: Axis.vertical,
                                shrinkWrap: true,
                                padding: const EdgeInsets.all(0.0),
                                itemCount: myData.length,
                                itemBuilder: (context, i) {
                                  print(prettyJson(myData[i], indent: 2));
                                  return Container();
                                }),
                          ),
                        ],
                      );
                    },
                  ),
                )),
          );
        });
  }
}
