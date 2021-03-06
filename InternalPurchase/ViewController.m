//
//  ViewController.m
//  InternalPurchase
//
//  Created by bailing on 2017/12/7.
//  Copyright © 2017年 zhufeng. All rights reserved.
//
#import "ViewController.h"
/*步骤1:首先是导入支付包*/
#import <StoreKit/StoreKit.h>
/*步骤2:设置代理服务器*/
@interface ViewController ()<SKPaymentTransactionObserver,SKProductsRequestDelegate>
@end
@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    /*步骤3.创建测试按钮*/
    UIButton *testBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, 100, 100, 100)];
    testBtn.backgroundColor = [UIColor redColor];
    [testBtn addTarget:self action:@selector(clickTestBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:testBtn];
    /*步骤4:设置支付服务的代理方法*/
    [[SKPaymentQueue defaultQueue]addTransactionObserver:self];
}
#pragma mark - 测试按钮
-(void)clickTestBtnAction2{
    /*步骤6:如果是app允许applepay*/
    if ([SKPaymentQueue canMakePayments]) {
        NSLog(@"支持苹果支付");
        /*步骤7:请求苹果后台商品*/
        [self getRequestAppleProduct2];
    }else{
        NSLog(@"不支持苹果支付");
    }
}
-(void)clickTestBtnAction{
    /*步骤5:判断点击按钮是否判断app是否允许app支付*/
    /*步骤6:如果是app允许applepay*/
    if ([SKPaymentQueue canMakePayments]) {
        NSLog(@"支持苹果支付");
        /*步骤7:请求苹果后台商品*/
        [self getRequestAppleProduct];
    }else{
        NSLog(@"不支持苹果支付");
    }
}
#pragma mark - 请求苹果商品
-(void)getRequestAppleProduct{
    /*步骤8:这里的com.bailing.InternalPurchase.test2就对应着苹果后台的商品的ID,他们是通过ID来关联*/
    NSArray *product = [[NSArray alloc]initWithObjects:@"com.bailing.InternalPurchase.test2", nil];
    NSSet *set = [NSSet setWithArray:product];
    /*步骤9:初始化请求*/
    SKProductsRequest *request = [[SKProductsRequest alloc]initWithProductIdentifiers:set];
    request.delegate = self;
    /*步骤10:开始请求*/
    [request start];
}
/*接收到产品的返回信息,然后用返回的商品信息进行发起购买请求*/
-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    NSArray *product = response.products;
    //如果是服务没有产品
    if ([product count]==0) {
        NSLog(@"nothing 没有产品");
        return;
    }
    SKProduct *requestProduct = nil;
    for (SKProduct *pro in product) {
        NSLog(@"%@", [pro description]);
        NSLog(@"%@", [pro localizedTitle]);
        NSLog(@"%@", [pro localizedDescription]);
        NSLog(@"%@", [pro price]);
        NSLog(@"%@", [pro productIdentifier]);
        /*步骤11:这里后台消费条目的ID和我这里的需要的请求是一样（用于确保订单的正确性）*/
        if ([pro.productIdentifier isEqualToString:@"com.bailing.InternalPurchase.test2"]) {
            requestProduct = pro;
        }else if ([pro.productIdentifier isEqualToString:@"com.zhufeng.test"]){
            requestProduct = pro;
        }
    }
    /*步骤12:发送购买请求*/
    SKPayment *payment = [SKPayment paymentWithProduct:requestProduct];
    [[SKPaymentQueue defaultQueue]addPayment:payment];
}
#pragma mark --请求返回的代理方法
/*请求失败*/
-(void)request:(SKRequest *)request didFailWithError:(NSError *)error{
    NSLog(@"请求失败:error:%@",error);
}
/*反馈请求到的产品信息结束后*/
-(void)requestDidFinish:(SKRequest *)request{
    NSLog(@"信息反馈结束");
}
/*监听购买结果*/
// 13.监听购买结果
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transaction{
        for (SKPaymentTransaction *tran in transaction) {
            switch (tran.transactionState) {
                case SKPaymentTransactionStatePurchased:
                    NSLog(@"交易完成");
                    /*这里是交易完成了，我们这里就是跳转到和自己的服务器交互了*/
                    [self completeTransaction:tran];
                    //结束交易
                    [[SKPaymentQueue defaultQueue]finishTransaction:tran];
                    break;
                case SKPaymentTransactionStatePurchasing:
                    NSLog(@"商品添加进列表");
                    //结束交易
                    [[SKPaymentQueue defaultQueue]finishTransaction:tran];
                    break;
                case SKPaymentTransactionStateRestored:
                    NSLog(@"已经购买过商品了");
                    [[SKPaymentQueue defaultQueue] finishTransaction:tran];
                    break;
                case SKPaymentTransactionStateFailed:
                    NSLog(@"交易失败");
                    [[SKPaymentQueue defaultQueue]finishTransaction:tran];
                    break;
                    default:
                    break;
            }
        }
}
// 14.交易结束,当交易结束后还要去appstore上验证支付信息是否都正确,只有所有都正确后,我们就可以给用户方法我们的虚拟物品了。
- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    NSString * str=[[NSString alloc]initWithData:transaction.transactionReceipt encoding:NSUTF8StringEncoding];
    NSString *environment=[self environmentForReceipt:str];
    NSLog(@"----- 完成交易调用的方法completeTransaction 1--------%@",environment);
    // 验证凭据，获取到苹果返回的交易凭据
    // appStoreReceiptURL iOS7.0增加的，购买交易完成后，会将凭据存放在该地址
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    // 从沙盒中获取到购买凭据
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    /**
     20      BASE64 常用的编码方案，通常用于数据传输，以及加密算法的基础算法，传输过程中能够保证数据传输的稳定性
     21      BASE64是可以编码和解码的
     22      */
    NSString *encodeStr = [receiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    
    NSString *sendString = [NSString stringWithFormat:@"{\"receipt-data\" : \"%@\"}", encodeStr];
    NSLog(@"_____%@",sendString);
    NSURL *StoreURL=nil;
    if ([environment isEqualToString:@"environment=Sandbox"]) {
        
        StoreURL= [[NSURL alloc] initWithString: @"https://sandbox.itunes.apple.com/verifyReceipt"];
    }
    else{
        
        StoreURL= [[NSURL alloc] initWithString: @"https://buy.itunes.apple.com/verifyReceipt"];
    }
    //这个二进制数据由服务器进行验证；zl
    NSData *postData = [NSData dataWithBytes:[sendString UTF8String] length:[sendString length]];
    
    NSLog(@"++++++%@",postData);
    NSMutableURLRequest *connectionRequest = [NSMutableURLRequest requestWithURL:StoreURL];
    
    [connectionRequest setHTTPMethod:@"POST"];
    [connectionRequest setTimeoutInterval:50.0];//120.0---50.0zl
    [connectionRequest setCachePolicy:NSURLRequestUseProtocolCachePolicy];
    [connectionRequest setHTTPBody:postData];
    
    //开始请求
    NSError *error=nil;
    NSData *responseData=[NSURLConnection sendSynchronousRequest:connectionRequest returningResponse:nil error:&error];
    if (error) {
        NSLog(@"验证购买过程中发生错误，错误信息：%@",error.localizedDescription);
        return;
    }
    NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
    NSLog(@"请求成功后的数据:%@",dic);
    //这里可以等待上面请求的数据完成后并且state = 0 验证凭据成功来判断后进入自己服务器逻辑的判断,也可以直接进行服务器逻辑的判断,验证凭据也就是一个安全的问题。楼主这里没有用state = 0 来判断。
    //  [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    NSString *product = transaction.payment.productIdentifier;
    NSLog(@"transaction.payment.productIdentifier++++%@",product);
    
    if ([product length] > 0)
    {
        NSArray *tt = [product componentsSeparatedByString:@"."];
        
        NSString *bookid = [tt lastObject];
        
        if([bookid length] > 0)
        {
            NSLog(@"打印bookid%@",bookid);
            //这里可以做操作吧用户对应的虚拟物品通过自己服务器进行下发操作,或者在这里通过判断得到用户将会得到多少虚拟物品,在后面（[self getApplePayDataToServerRequsetWith:transaction];的地方）上传上面自己的服务器。
        }
    }
    //此方法为将这一次操作上传给我本地服务器,记得在上传成功过后一定要记得销毁本次操作。调用[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    //[self getApplePayDataToServerRequsetWith:transaction];
}

//结束后一定要销毁
-(void)dealloc{
    [[SKPaymentQueue defaultQueue]removeTransactionObserver:self];
}
//对str的支付的字符串的东西进行的解析
-(NSString *)environmentForReceipt:(NSString *)str{
    str = [str stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    NSArray *arr = [str componentsSeparatedByString:@";"];
    //存储收据环境的变量
    NSString *enviroment = arr[2];
    NSLog(@"enviroment:%@",enviroment);
    return enviroment;
}
@end
