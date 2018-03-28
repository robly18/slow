import vector;
import std.conv;

const auto g = Vec2!float(0, 10);

const float dt = 0.01; //time per moment
const int momentsPerTurn = 600;
const int momentsPerSkip = 60;
const int groundJumpTime = 100;

const int skipStaminaPpt = 100;

const float secondsPerGameSecond = 0.5;

const float ghostTime = 1;
const int ghostMomentNo = to!int(ghostTime/dt); //moments per ghost
const int pastImageInterval = 1;
const int pastImageNo = ghostMomentNo / pastImageInterval;

const int momentsPerPreview = 60;

const float playerMass = 0.5;
const float playerInvMass = 1/playerMass;
const float maxJumpVelocity = 60; //in pixels per unit time
const float maxJumpImpulse = maxJumpVelocity * playerMass;
const float maxJumpForce = maxJumpImpulse/dt;
const float maxAirPulsePerMoment = 0.05;

const float maxTargetDistance = 200;
const float zeroTolerance = 3;

const int levelWidth = 2000;

const int screenWidth = 800, screenHeight = 600, taskbarHeight = 100;


const int barWidth = 50;
const int taskbarBarWidth = 400;

const int healthBgColor = 0x008800;
const int healthColor = 0x00FF00;
const int healthHeight = 7;
const int healthDistance = 6;
const int taskbarHealthHeight = 20;
const int healthTicks = 1;

const int cooldownBgColor = 0x880000;
const int cooldownColor = 0xdd3333;
const int cooldownHeight = 4;
const int cooldownDistance = 2;
const int taskbarCooldownHeight = 10;
const int cooldownTicks = momentsPerSkip;

const int taskbarPredictedCooldownHeight = 5;
const int predictedCooldownBgColor = 0x662266;
const int predictedCooldownColor = 0xFF55FF;
