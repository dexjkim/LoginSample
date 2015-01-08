//
//  ViewController.m
//  LoginSample
//
//  Created by Dexter Kim on 2015-01-05.
//  Copyright (c) 2015 DexMobile. All rights reserved.
//

#import "ViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import <GooglePlus/GooglePlus.h>
#import <GoogleOpenSource/GoogleOpenSource.h>
#import <TwitterKit/TwitterKit.h>

typedef NS_ENUM(NSUInteger, LoginMode) {
    LoginMode_NONE,
    LoginMode_FB,
    LoginMode_GPP,
    LoginMode_TW,
};

// It's from the google developer site
static NSString * const kClientId = @"602903741806-29gc29qh8caufee26c1hb6csvkumkfco.apps.googleusercontent.com";

@interface ViewController () <FBLoginViewDelegate, GPPSignInDelegate>

@property (weak, nonatomic) IBOutlet FBProfilePictureView *profileImageView;
@property (weak, nonatomic) IBOutlet FBLoginView *fbLoginButton;
@property (weak, nonatomic) IBOutlet GPPSignInButton *gppLoginButton;
@property (weak, nonatomic) IBOutlet TWTRLogInButton *twLoginButton;
@property (weak, nonatomic) IBOutlet UIButton *enterButton;
@property (readwrite, nonatomic) LoginMode loginMode;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
#ifdef SNS_LOGIN_AVAILABLE
    [self initFBLogin];
    [self initGooglePlusLogin];
    [self initTwitterLogin];
#else
    [self needLoginButtons:NO];
#endif
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Class Functions
- (void)needLoginButtons:(BOOL)shouldShow {
    self.fbLoginButton.hidden = !shouldShow;
    self.gppLoginButton.hidden = !shouldShow;
    self.twLoginButton.hidden = !shouldShow;
    self.enterButton.hidden = shouldShow;
}

#pragma mark Facebook Login
- (void)initFBLogin {
    self.fbLoginButton.delegate = self;
    self.fbLoginButton.readPermissions = @[@"public_profile", @"email", @"user_friends"];
}

#pragma mark Google+ Login
- (void)initGooglePlusLogin {
    GPPSignIn *signIn = [GPPSignIn sharedInstance];
    signIn.shouldFetchGooglePlusUser = YES;
    //signIn.shouldFetchGoogleUserEmail = YES;  // Uncomment to get the user's email
    
    // You previously set kClientId in the "Initialize the Google+ client" step
    signIn.clientID = kClientId;
    
    // Uncomment one of these two statements for the scope you chose in the previous step
    signIn.scopes = @[ kGTLAuthScopePlusLogin ];  // "https://www.googleapis.com/auth/plus.login" scope
    //signIn.scopes = @[ @"profile" ];            // "profile" scope
    
    // Optional: declare signIn.actions, see "app activities"
    signIn.delegate = self;
    
    [signIn trySilentAuthentication];
    
}

-(void)refreshInterfaceBasedOnSignIn {
    if ([[GPPSignIn sharedInstance] authentication]) {
        
        // The user is signed in.
        self.loginMode = LoginMode_GPP;
        
        // Perform other actions here, such as showing a sign-out button
        
    } else {
        // Perform other actions here
    }
}

- (void)gppSignOut {
    [[GPPSignIn sharedInstance] signOut];
}

#pragma mark Twitter Login
- (void)initTwitterLogin {
    [self twLogout];
    
    __weak ViewController *weakSelf = self;
    weakSelf.twLoginButton.logInCompletion = ^(TWTRSession *session, NSError *error) {
        if (session) {
            NSLog(@"signed in as %@", [session userName]);
            weakSelf.loginMode = LoginMode_TW;
            [weakSelf.twLoginButton setTitle:[NSString stringWithFormat:@"@%@ Logged in.", [session userName]] forState:UIControlStateNormal];
        } else {
            NSLog(@"error: %@", [error localizedDescription]);
            [self twLogout];
        }
    };
    
    self.twLoginButton = [TWTRLogInButton buttonWithLogInCompletion:weakSelf.twLoginButton.logInCompletion];
}

- (void)twLogout {
    [[Twitter sharedInstance] logOut];
}

#pragma mark Guest Login
- (IBAction)enterYourTube:(UIButton *)sender {
    self.loginMode = LoginMode_NONE;
    
    
}

#pragma mark - FBLoginViewDelegate
- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)user {
    self.profileImageView.profileID = [user objectID];
}

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    self.loginMode = LoginMode_FB;
    
    
}

- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    
}

- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error {
    NSString *alertMessage, *alertTitle;
    
    // If the user should perform an action outside of you app to recover,
    // the SDK will provide a message for the user, you just need to surface it.
    // This conveniently handles cases like Facebook password change or unverified Facebook accounts.
    if ([FBErrorUtility shouldNotifyUserForError:error]) {
        alertTitle = @"Facebook error";
        alertMessage = [FBErrorUtility userMessageForError:error];
        
        // This code will handle session closures that happen outside of the app
        // You can take a look at our error handling guide to know more about it
        // https://developers.facebook.com/docs/ios/errors
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession) {
        alertTitle = @"Session Error";
        alertMessage = @"Your current session is no longer valid. Please log in again.";
        
        // If the user has cancelled a login, we will do nothing.
        // You can also choose to show the user a message if cancelling login will result in
        // the user not being able to complete a task they had initiated in your app
        // (like accessing FB-stored information or posting to Facebook)
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
        NSLog(@"user cancelled login");
        
        // For simplicity, this sample handles other errors with a generic message
        // You can checkout our error handling guide for more detailed information
        // https://developers.facebook.com/docs/ios/errors
    } else {
        alertTitle  = @"Something went wrong";
        alertMessage = @"Please try again later.";
        NSLog(@"Unexpected error:%@", error);
    }
    
    if (alertMessage) {
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMessage
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

#pragma mark - GPPSignInDelegate
- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth error:(NSError *)error {
    NSLog(@"Received error %@ and auth object %@",error, auth);
    if (error) {
        // Do some error handling here.
    } else {
        [self refreshInterfaceBasedOnSignIn];
    }
}

- (void)didDisconnectWithError:(NSError *)error {
    if (error) {
        NSLog(@"Received error %@", error);
    } else {
        // The user is signed out and disconnected.
        // Clean up user data as specified by the Google+ terms.
    }
}


@end
