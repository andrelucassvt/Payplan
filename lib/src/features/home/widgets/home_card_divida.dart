import 'package:flutter/material.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';

class HomeCardDivida extends StatefulWidget {
  const HomeCardDivida({super.key});

  @override
  State<HomeCardDivida> createState() => _HomeCardDividaState();
}

class _HomeCardDividaState extends State<HomeCardDivida> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nome cartao',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              Text(
                '\$ 480,00',
                style: TextStyle(
                  //decoration: TextDecoration.lineThrough,
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    AppStrings.editarFatura,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Pago',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Switch(
                    value: true,
                    onChanged: (value) {},
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
