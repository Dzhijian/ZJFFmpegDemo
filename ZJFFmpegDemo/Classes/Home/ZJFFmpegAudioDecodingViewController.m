//
//  ZJFFmpegAudioDecodingViewController.m
//  ZJFFmpegDemo
//
//  Created by 邓志坚 on 2018/9/28.
//  Copyright © 2018 邓志坚. All rights reserved.
//

#import "ZJFFmpegAudioDecodingViewController.h"
#import <libavformat/avformat.h>
#import <libavutil/avutil.h>
#import <libswresample/swresample.h>

@interface ZJFFmpegAudioDecodingViewController ()

@end

@implementation ZJFFmpegAudioDecodingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"FFmpeg 音频解码";
    
    //第一步：组册组件->解码器、编码器等等…
    //视频解码器、视频编码器、音频解码器、音频编码器等等…
    av_register_all();
    
    //第二步：打开封装格式文件（解封装）
    //参数一：封装格式上下文
    AVFormatContext *avformat_context = avformat_alloc_context();
    //参数二：视频路径
    NSString* inFilePath = [[NSBundle mainBundle]pathForResource:@"video1" ofType:@".mp4"];
    const char *cinFilePath = [inFilePath UTF8String];
    //参数三：指定输入的格式
    //参数四：设置默认参数
    if (avformat_open_input(&avformat_context, cinFilePath, NULL, NULL) != 0) {
        NSLog(@"打开文件失败");
        return;
    }
    
    //第三步：查找音频流（视频流、字幕流等…）信息
    if (avformat_find_stream_info(avformat_context, NULL) < 0) {
        NSLog(@"查找失败");
        return;
    }
    
    //第四步：查找音频解码器
    //1、查找音频流索引位置
    int av_audio_stream_index = -1;
    for (int i = 0; i < avformat_context->nb_streams; ++i) {
        //判断流类型：视频流、音频流、字母流等等...
        if (avformat_context->streams[i]->codec->codec_type == AVMEDIA_TYPE_AUDIO){
            av_audio_stream_index = i;
            break;
        }
    }
    //2、根据视频流索引，获取音频解码器上下文
    AVCodecContext* avcodec_context = avformat_context->streams[av_audio_stream_index]->codec;
    //3、根据音频解码器上下文的ID，然后查找音频解码器
    AVCodec* avcode = avcodec_find_decoder(avcodec_context->codec_id);
    
    //第五步：打开音频解码器
    if ( avcodec_open2(avcodec_context, avcode, NULL)!=0) {
        NSLog(@"打开解码器失败");
    }
    NSLog(@"解码器名称：%s",avcode->name);
    //第六步：循环读取每一帧音频压缩数据
    //参数一：封装格式上下文呢
    //参数二：音频压缩数据(一帧)
    //返回值：>=0表示读取成功，<0表示失败或者解码完成(读取完毕)
    //准备一帧音频压缩数据
    AVPacket *avPacket = (AVPacket *) av_malloc(sizeof(AVPacket));
    //准备一帧音频采样数据
    AVFrame *avFrame = av_frame_alloc();
    
    //3、类型转换->统一转换为pcm格式->swr_convert()
    //初始化音频采样数据上下文
    //3.1：开辟一块内存空间
    SwrContext *swrContext = swr_alloc();
    //3.2：设置默认配置
    //参数一：音频采样数据上下文
    //参数二：输出声道布局(立体声、环绕声...)
    //参数三：输出采样精度(编码)
    //参数四：输出采样率
    //参数五：输入声道布局
    int64_t in_ch_layout = av_get_default_channel_layout(avcodec_context->channels);
    //参数六：输入采样精度
    //参数七：输入采样率
    //参数八：日志统计开始位置
    //参数九：日志上下文
    swr_alloc_set_opts(swrContext,
                       AV_CH_LAYOUT_STEREO,
                       AV_SAMPLE_FMT_S16,
                       avcodec_context->sample_rate,
                       in_ch_layout,
                       avcodec_context->sample_fmt,
                       avcodec_context->sample_rate,
                       0,
                       NULL);
    
    //3.3：初始化上下文
    swr_init(swrContext);
    
    //3.4：统一输出音频采样数据格式->pcm
    int MAX_AUDIO_SIZE = 44100 * 2;
    uint8_t *out_buffer = (uint8_t *) av_malloc(MAX_AUDIO_SIZE);
    
    //4、获取缓冲区实际大小
    int out_nb_channels = av_get_channel_layout_nb_channels(AV_CH_LAYOUT_STEREO);
    
    //5.1 打开文件
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         
                                                         NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *tmpPath = [path stringByAppendingPathComponent:@"temp"];
    [[NSFileManager defaultManager] createDirectoryAtPath:tmpPath withIntermediateDirectories:YES attributes:nil error:NULL];
    NSString* outFilePath = [tmpPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Test.pcm"]];
    
    const char *outfile = [outFilePath UTF8String];
    FILE* file_pcm = fopen(outfile, "wb+");
    if (file_pcm == NULL){
        NSLog(@"输出文件打开失败");
        return;
    }
    
    int current_index = 0;
    
    while (av_read_frame(avformat_context, avPacket) >= 0) {
        //判定这一帧数据是否音频流(视频流、音频流、字母流等等...)
        //1、音频解码->判定流类型
        if (avPacket->stream_index == av_audio_stream_index) {
            //第七步：解码
            //2、音频解码->开始解码
            //2.1 发送数据包->一帧音频压缩数据->acc格式、mp3格式
            avcodec_send_packet(avcodec_context, avPacket);
            //2.2 解码数据包->解码->一帧音频采样数据->pcm格式
            int ret = avcodec_receive_frame(avcodec_context, avFrame);
            if (ret == 0) {
                //表示解码成功，否则失败
                //3、类型转换->统一转换为pcm格式->swr_convert()
                //为什么呢？因为解码之后的音频采样数据格式->有很多种类型->保证格式一致
                //参数一：音频采样数据上下文
                //参数二：输出音频采样数据
                //参数三：输出音频采样数据大小
                //参数四：输入音频采样数据
                //参数五：输入音频采样数据大小
                swr_convert(swrContext,
                            &out_buffer,
                            MAX_AUDIO_SIZE,
                            (const uint8_t **) avFrame->data,
                            avFrame->nb_samples);
                
                //4、获取缓冲区实际大小
                //参数一：行大小
                //参数二：输出声道数量（单声道、双声道）
                //参数三：输入大小
                //参数四：输出音频采样数据格式
                //参数五：字节对齐方式->默认是1
                int buffer_size = av_samples_get_buffer_size(NULL,
                                                             out_nb_channels,
                                                             avFrame->nb_samples,
                                                             avcodec_context->sample_fmt,
                                                             1);
                
                //5、写入文件
                //5.1 打开文件
                //5.2 写入文件
                fwrite(out_buffer, 1, buffer_size, file_pcm);
                current_index++;
                NSLog(@"当前解码到了第%d帧", current_index);
            }
        }
    }
    //第八步：释放资源（内存）->关闭解码器
    fclose(file_pcm);
    av_packet_free(&avPacket);
    av_frame_free(&avFrame);
    free(out_buffer);
    avcodec_close(avcodec_context);
    avformat_free_context(avformat_context);
}


@end
