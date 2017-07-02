import vector;

const auto g = Vec2!float(0, 10);

const float dt = 0.01;
const int momentsPerTurn = 600;
const int momentsPerSkip = 60;
const int timeBetweenShots = 80;
const int groundJumpTime = 100;

const float secondsPerGameSecond = 0.4;

const float maxJumpForce = 40;
const float maxAirPulsePerMoment = 0.05;
const float pixelsPerForceUnit = 2;

const int levelWidth = 2000;

const int screenWidth = 800, screenHeight = 600;


const int pastImageNo = 100;
const int pastImageInterval = 1;
const float bulletVelocity = 250;
const auto bulletSize = Vec2!float(10, 10);


const int healthBgColor = 0x008800;
const int healthColor = 0x00FF00;
const int healthWidth = 8;


const int cooldownBgColor = 0x880000;
const int cooldownColor = 0xdd3333;
const int cooldownWidth = 8;

const float cooldownBarScalingFactor = 0.035;