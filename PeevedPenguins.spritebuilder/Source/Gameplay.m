//
//  Gameplay.m
//  PeevedPenguins
//
//  Created by Toni Mäki-Leppilampi on 16.11.2014.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Gameplay.h"
#import "CCPhysics+ObjectiveChipmunk.h"
#import "Penguin.h"


@implementation Gameplay {
    CCPhysicsNode *_physicsNode;
    CCNode *_catapultArm;
    CCNode *_levelNode;
    CCNode *_contentNode;
    CCNode *_pullbackNode;
    CCNode *_mouseJointNode;
    CCNode *_perhosAnkkuri;
    CCNode *_perhosContainer;
    CCPhysicsJoint *_mouseJoint;
    Penguin *_currentPenguin;
    CCPhysicsJoint *_penguinCatapultJoint;
    CCAction *_followPenguin;
    
    CCNode *_kukkaContainer;

}

static const float MIN_SPEED = 50.f;
static const float GRAVITY = -150.f;
int turnover = 0;

-(void)flipKukka {
    CCSprite *kukka;
    kukka = _kukkaContainer.children[0];
//    _kukkaContainer.scaleX = -1;
    CCLOG(@"Käännetty! %d", kukka.flipX);
    if (kukka.flipX == 0) {
        kukka.flipX = 180;
    } else {
        kukka.flipX = 0;
    }
    [_kukkaContainer.physicsBody applyImpulse:ccp(0.f, 2000.f)];
    [_kukkaContainer.physicsBody applyAngularImpulse:30000.f];
}

- (void)didLoadFromCCB {
    self.userInteractionEnabled = TRUE;
    CCScene *level = [CCBReader loadAsScene:@"Levels/Level1"];
    [_levelNode addChild:level];
    _pullbackNode.physicsBody.collisionMask = @[];
    _mouseJointNode.physicsBody.collisionMask = @[];

    _perhosAnkkuri.physicsBody.collisionMask = @[];
    _perhosContainer.physicsBody.collisionMask = @[];
    
    _physicsNode.collisionDelegate = self;
    
    _physicsNode.debugDraw = TRUE;
    
    [self setGravity];
//    [self flipKukka];

}

-(void)setGravity {
    _levelNode.physicsNode.gravity = CGPointMake(0.f, GRAVITY);
}

- (void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    
    if (CGRectContainsPoint([_catapultArm boundingBox], touchLocation))
    {
        _mouseJointNode.position = touchLocation;
        
        _mouseJoint = [CCPhysicsJoint connectedSpringJointWithBodyA:_mouseJointNode.physicsBody bodyB:_catapultArm.physicsBody anchorA:ccp(0, 0) anchorB:ccp(34, 138) restLength:0.f stiffness:3000.f damping:150.f];
        
        // Pingviinit mukaan!
        _currentPenguin = (Penguin*)[CCBReader load:@"Penguin"];
        CGPoint penguinPosition = [_catapultArm convertToWorldSpace:ccp(34, 138)];
        _currentPenguin.position = [_physicsNode convertToNodeSpace:penguinPosition];
        [_physicsNode addChild:_currentPenguin];
        _currentPenguin.physicsBody.allowsRotation = FALSE;
        
        _penguinCatapultJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_currentPenguin.physicsBody bodyB:_catapultArm.physicsBody anchorA:_currentPenguin.anchorPointInPoints];
    }
}

- (void)touchMoved:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    _mouseJointNode.position = touchLocation;
}

- (void)releaseCatapult {
    _currentPenguin.launched = TRUE;
    if (_mouseJoint != nil)
    {
        [_mouseJoint invalidate];
        _mouseJoint = nil;
        
        [_penguinCatapultJoint invalidate];
        _penguinCatapultJoint = nil;
        _currentPenguin.physicsBody.allowsRotation = TRUE;
        
        _followPenguin = [CCActionFollow actionWithTarget:_currentPenguin worldBoundary:self.boundingBox];
        [_contentNode runAction:_followPenguin];
    }
}

-(void)nextAttempt
{
    _currentPenguin = nil;
    [_contentNode stopAction:_followPenguin];
    
    CCActionMoveTo *actionMoveTo= [CCActionMoveTo actionWithDuration:1.f position:ccp(0, 0)];
    [_contentNode runAction:actionMoveTo];
}


- (void)touchEnded:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    [self releaseCatapult];
}

- (void)touchCancelled:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    [self releaseCatapult];
}

//- (void)launchPenguin {
//    CCNode* penguin = [CCBReader load:@"Penguin"];
//    penguin.position = ccpAdd(_catapultArm.position, ccp(16,50));
    
//    [_physicsNode  addChild:penguin];
    
//    CGPoint launchDirection = ccp(1, 0);
//    CGPoint force = ccpMult(launchDirection, 8000);
//    [penguin.physicsBody applyForce:force];
    
//    self.position = ccp(0, 0);
//}

-(void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair seal:(CCNode *)nodeA wildcard:(CCNode *)nodeB
{
//    CCLOG(@"HYLJE TÖRMÄSI!");
    float energy = [pair totalKineticEnergy];
    if (energy > 5000.f) {
        [[_physicsNode space] addPostStepBlock:^{
            [self sealRemoved:nodeA];
        } key:nodeA];
    }
}

-(void)sealRemoved:(CCNode *)seal
{
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"SealExplosion"];
    explosion.autoRemoveOnFinish = TRUE;
    explosion.position = seal.position;
    [seal.parent addChild:explosion];
    
    [seal removeFromParent];
}

-(void)update:(CCTime)delta
{
    if (_currentPenguin.launched)
    {
        if (ccpLength(_currentPenguin.physicsBody.velocity) < MIN_SPEED)
        {
            [self nextAttempt];
            return;
        }
        
        int xMin = _currentPenguin.boundingBox.origin.x;
        if (xMin < self.boundingBox.origin.x)
        {
            [self nextAttempt];
            return;
        }
        
        int xMax = xMin + _currentPenguin.boundingBox.size.width;
        if (xMax > (self.boundingBox.origin.x + self.boundingBox.size.width))
        {
            [self nextAttempt];
            return;
        }
    }
}

- (void)retry {
    [[CCDirector sharedDirector] replaceScene: [CCBReader loadAsScene:@"Gameplay"]];
}

@end
