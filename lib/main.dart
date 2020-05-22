import 'dart:math';

import 'package:flame/components/animation_component.dart';
import 'package:flame/components/component.dart';
import 'package:flutter/material.dart';
import 'package:flame/gestures.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'dart:ui';

var game;
int score = 0;
bool gameOver = false;
bool gameStart = false;
double coronaSpeed = 70.0;
const CoronaSize = 50.0;
List<Corona> coronaList = <Corona>[];
List<Bullet> bulletList = <Bullet>[];
//double time = 1;
main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Flame.util.setPortrait();
  Flame.images.loadAll(['fire.png', 'bullet.png','corona.png','explosion-4.png']);
  var dimensions = await Flame.util.initialDimensions();
  game = FGame(dimensions);
  runApp(MaterialApp(
    home: Scaffold(
    body: Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/background.jpg"), //canvas is black so bg image is masked
          fit: BoxFit.cover,
        ),
      ),
      child: GameWrapper(game),
    ),
  )));
}
class GameWrapper extends StatelessWidget {
  final FGame game;
  GameWrapper(this.game);
  @override
  Widget build(BuildContext context) {
    return game.widget;
  }
}

double bulletDx;
double bulletDy;
Corona corona;
class FGame extends BaseGame with TapDetector {
  Size dimensions;
  FGame(this.dimensions);
  @override
  void render(Canvas canvas) {
    if(gameOver == false && gameStart == true) { 
      super.render(canvas);
      String text = 'Score: $score';
      TextSpan span = TextSpan(text: text, style: TextStyle(fontSize: 44.0, color:Colors.white));
      TextPainter textPainter = TextPainter(text: span, textDirection: TextDirection.ltr);
      textPainter.layout(minWidth: 0.0);
      textPainter.paint(canvas, Offset(size.width/4.4,size.height - 50));    }
    if(gameOver == true)
    {
      // super.render(canvas);
      TextSpan span = TextSpan(text: 'Corona will\neventually\ncatch you\n\nGame Over\nScore: $score\n\nTap to Restart', style: TextStyle(fontSize: 37.0, color:Colors.white));
      TextPainter textPainter = TextPainter(text: span, textDirection: TextDirection.ltr);
      textPainter.layout(minWidth: 0.0);
      textPainter.paint(canvas, Offset(size.width/5,size.height/4));
    }
    if(gameStart == false)
    {
      // super.render(canvas);
      TextSpan span = TextSpan(text: 'Tap to Start\nKilling Corona', style: TextStyle(fontSize: 40.0, color:Colors.white));
      TextPainter textPainter = TextPainter(text: span, textDirection: TextDirection.ltr);
      textPainter.layout(minWidth: 0.0);
      textPainter.paint(canvas, Offset(size.width/5,size.height/2.1));
    }
  }
  
  double creationTimer = 0.0;
  @override 
  void update(double t) {
    creationTimer += t;
   // time++;
    if(creationTimer>=2 && gameOver==false) {
        creationTimer = 0.0;
        if(score%5==0) {
          coronaSpeed+=10;
        }
        for(int i =1; i<=(score/30)+1 && i<=7;i++) { 
          corona = Corona(dimensions);
          add(corona);
          coronaList.add(corona);
        }
    }
    if(bulletDx != null && bulletDy != null && coronaList.isNotEmpty && bulletList.length <= coronaList.length+1)
    {
        bullet = Bullet(dimensions);
        add(bullet);
        bulletList.add(bullet);
        Flame.audio.play('corona go.mp3');
        Flame.audio.clearAll();
        bulletDx=null;
        bulletDx=null;
    }
    else {
        bulletDx = null;
        bulletDy = null;
    }
    if(gameOver==true) {
        coronaSpeed = 70.0;
        coronaList.every((element) => element.remove=true);
        bulletList.every((element) => element.remove=true);
    }
    if(gameOver== false && gameStart==true)
        super.update(t);
  }

  
 
  void onTapDown(TapDownDetails details)
  {
    if(gameOver == false && gameStart == true) {
      bulletDx = details.globalPosition.dx;
      bulletDy = details.globalPosition.dy;
    }
    else if(gameStart == false) {
      gameStart = true;
    }
    else {
      gameOver = false;
      score = 0;
    }
  }
}

class Corona extends SpriteComponent {
  Size dimensions;
  Corona(this.dimensions) : super.square(CoronaSize, 'corona.png');
  double maxY;
  bool remove = false;
  @override 
  void update(double t) {
    y += t * coronaSpeed;
  }
  @override 
  bool destroy() {
    if(y>maxY)
    {
      gameOver = true;
      return true;
    }
    return remove;
  }
  @override 
  void resize(Size size) {
    this.x = (size.width*Random().nextDouble())-CoronaSize/2;
    this.y = 0;
    this.maxY = size.height;
  }
}

class Explosion extends AnimationComponent {
    Explosion(Corona corona) : super.sequenced(CoronaSize, CoronaSize,
                'explosion-4.png', 7,textureHeight: 31.0, textureWidth: 31.0)
    {
      this.x = corona.x;
      this.y = corona.y;
      this.animation.stepTime = 0.75/7;
    }
    bool destroy()
    {
      return this.animation.isLastFrame;
    }
}

const BulletSPEED = 60.0;
const BulletSize = 25.0;
Bullet bullet;
class Bullet extends SpriteComponent {
  Size dimensions;
  Bullet(this.dimensions) : super.square(BulletSize, 'fire.png');
  double maxX;
  bool remove = false;
  @override 
  void update(double t) {
    y -= t * BulletSPEED;
    if(coronaList.isNotEmpty)
    {
        if(coronaList.any((element) {
            if(this.toRect().contains(element.toRect().bottomCenter) || 
            this.toRect().contains(element.toRect().bottomLeft) || this.toRect().contains(element.toRect().bottomRight)
            || this.toRect().contains(element.toRect().center))
            {
                //print("collided");
                score++;
                Explosion explode = Explosion(element);
                game.add(explode);
                Flame.audio.play('go corona.mp3');
                element.remove = true;  
                Flame.audio.clearAll();
                coronaList.remove(element);
                if(explode.destroy())
                    game.remove(explode);
                return true;
            }
            return false;
        }))
        {
            remove = true;
            bulletList.remove(this);
        }
    }
    if(this.y<maxX)
    {
        remove = true;
        bulletList.remove(this);
    }
  }
  @override 
  bool destroy() {
    if(gameOver==true)
    {
      coronaSpeed = 70.0;
      return true;
    }
    return remove;
  }
  @override 
  void resize(Size size) {
    this.x = bulletDx;
    this.y = size.height/1.1;
    this.maxX = 0.0;
  }
}