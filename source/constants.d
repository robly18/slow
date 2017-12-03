import vector;
import std.conv;

const auto g = Vec2!float(0, 10);

const float dt = 0.01; //time per moment
const int momentsPerTurn = 600;
const int momentsPerSkip = 60;
const int timeBetweenShots = 80;
const int groundJumpTime = 100;

const float secondsPerGameSecond = 0.5;

const float ghostTime = 1;
const int ghostMomentNo = to!int(ghostTime/dt); //moments per ghost
const int pastImageInterval = 1;
const int pastImageNo = ghostMomentNo / pastImageInterval;

const float playerMass = 0.5;
const float playerInvMass = 1/playerMass;
const float maxJumpVelocity = 60; //in pixels per unit time
const float maxJumpImpulse = maxJumpVelocity * playerMass;
const float maxJumpForce = maxJumpImpulse/dt;
const float maxAirPulsePerMoment = 0.05;

const int levelWidth = 2000;

const int screenWidth = 800, screenHeight = 600;

const float bulletVelocity = 250;
const auto bulletSize = Vec2!float(10, 10);


const int healthBgColor = 0x008800;
const int healthColor = 0x00FF00;
const int healthHeight = 4;
const int healthDistance = 2;
const float healthScale = 1;


const int cooldownBgColor = 0x880000;
const int cooldownColor = 0xdd3333;
const int cooldownHeight = 4;
const int cooldownDistance = healthDistance + healthHeight + 1;

const float cooldownBarScalingFactor = 0.1;