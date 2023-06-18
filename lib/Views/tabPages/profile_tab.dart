import 'package:car_pool_driver/Views/tabPages/update_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Constants/styles/colors.dart';
import '../../authentication/login_screen.dart';
import '../../global/global.dart';
import '../../widgets/profile_widget.dart';

class ProfileTabPage extends StatefulWidget {
  const ProfileTabPage({Key? key}) : super(key: key);

  @override
  State<ProfileTabPage> createState() => _ProfileTabPageState();
}

class _ProfileTabPageState extends State<ProfileTabPage> {
  final auth = FirebaseAuth.instance;
  final ref = FirebaseDatabase.instance.ref('users');
  late String name, email, key;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: ColorsConst.white,
        body: StreamBuilder(
            stream: ref.child(currentFirebaseUser!.uid.toString()).onValue,
            builder: (context, AsyncSnapshot snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasData) {
                Map<dynamic, dynamic> map = snapshot.data.snapshot.value;
                name = map['name'];
                email = map['email'];
                key = currentFirebaseUser!.uid.toString();
                return ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    ProfileWidget(
                        imagePath: map['userImage'], onClicked: () async {}),

                    const SizedBox(
                      height: 15,
                    ),
                    buildName(),
                    const Divider(),
                    const SizedBox(
                      height: 15,
                    ),
                    settingsTile(context, userKey: key),

                    //DriverStats(),
                  ],
                );
              } else {
                return Center(
                    child: Text('Something went wrong',
                        style: Theme.of(context).textTheme.titleMedium));
              }
            }));
  }

  Widget buildName() => Column(
        children: [
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            email,
            style: const TextStyle(color: ColorsConst.grey),
          )
        ],
      );

  Widget buildStat() => Padding(
        padding: const EdgeInsets.only(left: 2.0, right: 2.0),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly, //Center Row contents horizontally,
          children: [
            Row(
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.star, color: Colors.yellow),
                ),
                Text(
                  '4.5',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('325'),
                ),
                Text('ratings'),
              ],
            )
          ],
        ),
      );
}

Widget settingsTile(BuildContext context, {required userKey}) {
  final Uri emailLaunch = Uri(
      scheme: 'mailto',
      path: 'ridepool@gmail.com',
      queryParameters: {'subject': 'Feedback about your app'});
  return Column(children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(8, 1, 8, 8),
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: ((context) => UpdateProfile(
                    userKey: userKey,
                  ))));
        },
        leading: const Icon(Icons.person),
        title: const Text('Edit Account'),
      ),
    ),
    Padding(
      padding: const EdgeInsets.fromLTRB(8, 1, 8, 8),
      child: ListTile(
        onTap: () {},
        leading: const Icon(Icons.notifications),
        title: const Text('Notifications'),
      ),
    ),
    const Divider(
      endIndent: 18,
      indent: 18,
    ),
    Padding(
      padding: const EdgeInsets.fromLTRB(8, 1, 8, 8),
      child: ListTile(
        onTap: () {
          launchUrl(emailLaunch);
        },
        leading: const Icon(Icons.feedback),
        title: const Text('Feedback'),
      ),
    ),
    Padding(
      padding: const EdgeInsets.fromLTRB(8, 1, 8, 8),
      child: ListTile(
        onTap: () {
          termsDialog(context);
        },
        leading: const Icon(Icons.receipt),
        title: const Text('Terms & Conditions'),
      ),
    ),
    const Divider(
      endIndent: 18,
      indent: 18,
    ),
    Padding(
      padding: const EdgeInsets.fromLTRB(8, 1, 8, 8),
      child: ListTile(
        onTap: () {
          fAuth.signOut();
          Navigator.pop(context);
          Navigator.push(
              context, MaterialPageRoute(builder: (c) => LoginScreen()));
        },
        leading: const Icon(Icons.logout),
        title: const Text('Logout'),
      ),
    ),
  ]);
}

Future<void> termsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: const <Widget>[
              Text('''1. Definitions
The following words and terms shall have the meanings set forth below when they are used in these Terms and Conditions.
1.1.“Contents” means information such as text, sounds, music, images, videos, software, programs, computer code, and other information. 
1.2.“Subject Contents” means Contents that may be accessed through the Services. 
1.3.“Submitted Contents” means Contents that Users have submitted, transmitted or uploaded on or to the Services. 
1.4.“Coins” refers to the prepaid payment instrument or the like which Users may exchange for Contents and services offered by Ride-Pool which are provided for a fee within the Services. 
1.5.“Separate Terms and Conditions” means terms and conditions separate from these Terms and Conditions that pertain to the Services released or uploaded by Ride-Pool under names such as “terms,” “guidelines,” “policies,” or the like.
2.Agreement to these Terms and Conditions
2.1.All Users shall use the Services in accordance with these Terms and Conditions. Users may not use the Services unless they agree to these Terms and Conditions. 
2.2.Users who are minors may only use the Services by obtaining prior consent from their parents or legal guardians. Furthermore, if Users will be using the Services on behalf of, or for the purposes of, a business enterprise, then such business enterprise must also agree to these Terms and Conditions prior to using the Services. 
2.3.If there are Separate Terms and Conditions applicable to the Services, Users shall also comply with such Separate Terms and Conditions as well as these Terms and Conditions in using the Services.
3.Modification to these Terms and Conditions
Ride-Pool may modify these Terms and Conditions when Ride-Pool deems it to be necessary, within the scope of the purposes of the Services. In such case, Ride-Pool will indicate the contents of the modified version of these Terms and Conditions, as well as the effective date of the modification, on the Services or on Ride-Pool’s website, or will publicize the same to Users by notifying Users in the manner prescribed by Ride-Pool.The modified version of these Terms and Conditions shall become effective as of the effective date thereof.
4.Account
4.1.When using the Services, Users may need to set up an account by registering certain information. Users must register true, accurate and complete information, and must revise the same to keep such information up-to-date at all times.
4.2.If Users register any authentication information when using the Services, they must exercise due care in handling such information at their own responsibility to ensure that such information is not used in an unlawful manner. Ride-Pool may treat any and all activities conducted under the authentication information as activities that have been conducted by the User with whom the authentication information is registered.
4.3.Any User who has registered for the Services may delete such User’s account and cancel the Services at any time.
4.4.Ride-Pool reserves the right to delete any account that has been inactive for a period of one (1) year or more since its last activation, without any prior notice to the applicable User.
4.5.Any and all rights of a User to use the Service shall cease to exist when such User’s account has been deleted for any reason. Please take note that an account cannot be retrieved even if a User has accidentally deleted their account.
4.6.Each account in the Services is for exclusive use and belongs solely to the User of such account. Users may not transfer, lease or otherwise dispose their rights to use the Service to any third party, nor may the same be inherited or succeeded to by any third party.
5.Privacy
5.1.Ride-Pool places top priority on the privacy of its Users.
5.2.Ride-Pool promises to exercise the utmost care and attention to its security measures to ensure the safe management of any and all information collected from Users.
6.Provision of the Service
6.1.Users shall supply PCs, mobile phone devices, smartphones and other communication devices, operating systems, communication methods and electricity, etc. necessary for using the Services at their own responsibility and expense.
6.2.Ride-Pool reserves the right to limit access to all or part of the Services by Users depending upon conditions that Ride-Pool considers necessary, such as the age and identification of User, current registration status, and the like.
6.3.Ride-Pool reserves the right to modify, at Ride-Pool's discretion, all or part of the Services as Ride-Pool determines necessary anytime without any prior notice to Users.
6.4.Ride-Pool may cease providing all or part of the Services without any prior notice to Users in case of the occurrence of any of the following:
(1)When conducting maintenance or repair of systems;
(2)When the Services cannot be provided due to force majeure such as an accident (fire, power outage, etc.), act of God, war, riot, labor dispute;
(3)When there is system failure or heavy load on the system;
7.Advertisements
Ride-Pool reserves the right to post advertisements for Ride-Pool or a third party on the Services.
8.Restricted Matters
Ride-Pool prohibits Users from engaging in any of the following acts when using the Services:
8.1.Acts that violate the laws and regulations, court verdicts, resolutions or orders, or administrative measures that are legally binding;
8.2.Acts that may be in violation of public order, morals or customs;
8.3.Acts that infringe intellectual property rights, such as copyrights, trademarks and patent rights, rights to fame, privacy, and all other rights granted by law or by a contract with Ride-Pool and/or a third party;
8.4.Acts of posting or transmitting excessively violent or explicit sexual expressions; expressions that amount to child pornography or child abuse; expressions that lead to discrimination by race, national origin, creed, gender, social status, family origin, etc.; expressions that induce or encourage suicide, self-injurious behavior or drug abuse; or expressions that include anti-social content and lead to the discomfort of others;
8.5.Acts that lead to the misrepresentation of Ride-Pool and/or a third party or that intentionally spread false information;
8.6.Acts of sending the same or similar messages to a large, indefinite number of Users (except for those approved by Ride-Pool), indiscriminately adding other Users as friends or to group chats, or any other acts deemed by Ride-Pool to constitute spamming;
8.7.Acts of exchanging the right to use the Services or Contents into cash, property or other economic benefits, other than by using the method prescribed by Ride-Pool;
8.8.Acts of using the Services for sales, marketing, advertising, solicitation or other commercial purposes (except for those approved by Ride-Pool); using the Services for the purpose of sexual conduct or obscene acts; using the Services for the purpose of meeting or engaging in sexual encounters with an unknown third party; using the Services for the purpose of harassment or libellous attacks against other Users; or otherwise using the Services for purposes other than as intended by the Services;
8.9.Acts that benefit or involve collaboration with anti-social groups;
8.10.Acts that are related to religious activities or invitations to certain religious groups; 
8.11.Acts of unauthorized or improper collection, disclosure, or provision of any other person's personal information, registered information, user history, or the like;
8.12.Acts of interfering with the servers and/or network systems of the Services; fraudulently manipulating the Services by means of bots, cheat tools, or other technical measures; deliberately using defects of the Services; making unreasonable inquires and/or undue claims such as repeatedly asking the same questions beyond what is necessary, and other acts of interfering with or hindering Ride-Pool's operation of the Services or other Users’ use of the Services;
8.13.Acts of decoding the source code of the Services, such as by way of reverse engineering, disassembling or the like, for unreasonable purposes or in an unfair manner;
8.14.Acts that aid or encourage any acts stated in Clauses 13.1 to 13.13 above; and
8.15.Acts other than those set forth in Clauses 13.1 to 13.14 that Ride-Pool reasonably deems to be inappropriate.
9.NO WARRANTY
Ride-Pool SHALL PROVIDE NO WARRANTY, EITHER EXPRESSLY OR IMPLIEDLY, WITH RESPECT TO THE SERVICES (INCLUDING THE SUBJECT CONTENTS), THAT THERE ARE NO DEFECTS (INCLUDING, WITHOUT LIMITATION, FAULTS WITH RESPECT TO SECURITY, ETC., ERRORS OR BUGS, OR VIOLATIONS OF RIGHTS) OR AS TO THE SAFETY, RELIABILITY, ACCURACY, COMPLETENESS, EFFECTIVENESS AND FITNESS FOR A PARTICULAR PURPOSE. Ride-Pool WILL IN NO WAY BE RESPONSIBLE FOR PROVIDING USERS WITH THE SERVICES AFTER DELETING SUCH DEFECTS. 
10.Relationship between these Terms and Conditions and Laws and Regulations
If the terms of these Terms and Conditions violate any laws and regulations applicable to an agreement between Users and Ride-Pool with respect to the Services (including, without limitation, the laws of the country), such terms, to the extent of such violation, shall not apply to the agreement with the Users; provided, however, that the remaining terms of these Terms and Conditions shall not be affected.'''),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

class ReusableRow extends StatelessWidget {
  final String title, value;
  final IconData iconData;

  const ReusableRow(
      {Key? key,
      required this.title,
      required this.value,
      required this.iconData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, right: 35.0),
      child: Column(
        children: [
          ListTile(
            title: Text(title),
            leading: Icon(iconData),
            trailing: Text(value,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
