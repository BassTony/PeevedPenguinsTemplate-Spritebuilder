//
//  Gameplay.m
//  PeevedPenguins
//
//  Created by Toni Mäki-Leppilampi on 16.11.2014.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Gameplay.h"

@implementation Gameplay {
    CCPhysicsNode *_physicsNode;
    CCNode *_catapultArm;
    CCNode *_levelNode;
    CCNode *_contentNode;
    CCNode *_pullbackNode;
    CCNode *_mouseJointNode;
    CCPhysicsJoint *_mouseJoint;
    CCNode *_currentPenguin;
    CCPhysicsJoint *_penguinCatapultJoint;
}

- (void)didLoadFromCCB {
    self.userInteractionEnabled = TRUE;
    CCScene *level = [CCBReader loadAsScene:@"Levels/Level1"];
    [_levelNode addChild:level];
    _pullbackNode.physicsBody.collisionMask = @[];
    _mouseJointNode.physicsBody.collisionMask = @[];
    
    _physicsNode.collisionDelegate = self;
    
    _physicsNode.debugDraw = TRUE;
}

- (void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    
    if (CGRectContainsPoint([_catapultArm boundingBox], touchLocation))
    {
        _mouseJointNode.position = touchLocation;
        
        _mouseJoint = [CCPhysicsJoint connectedSpringJointWithBodyA:_mouseJointNode.physicsBody bodyB:_catapultArm.physicsBody anchorA:ccp(0, 0) anchorB:ccp(34, 138) restLength:0.f stiffness:3000.f damping:150.f];
        
        // Pingviinit mukaan!
        _currentPenguin = [CCBReader load:@"Penguin"];
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
    if (_mouseJoint != nil)
    {
        [_mouseJoint invalidate];
        _mouseJoint = nil;
        
        [_penguinCatapultJoint invalidate];
        _penguinCatapultJoint = nil;
        _currentPenguin.physicsBody.allowsRotation = TRUE;
        
        CCActionFollow *follow = [CCActionFollow actionWithTarget:_currentPenguin worldBoundary:self.boundingBox];
        [_contentNode runAction:follow];
        
    }
}

- (void)touchEnded:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    [self releaseCatapult];
}

- (void)touchCancelled:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    [self releaseCatapult];
}

- (void)launchPenguin {
//    CCNode* penguin = [CCBReader load:@"Penguin"];
//    penguin.position = ccpAdd(_catapultArm.position, ccp(16,50));
    
//    [_physicsNode  addChild:penguin];
    
//    CGPoint launchDirection = ccp(1, 0);
//    CGPoint force = ccpMult(launchDirection, 8000);
//    [penguin.physicsBody applyForce:force];
    
//    self.position = ccp(0, 0);
}

-(void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair seal:(CCNode *)nodeA wildcard:(CCNode *)nodeB
{
    CCLOG(@"HYLJE TÖRMÄSI!");
}

- (void)retry {
    [[CCDirector sharedDirector] replaceScene: [CCBReader loadAsScene:@"Gameplay"]];
}

@end
