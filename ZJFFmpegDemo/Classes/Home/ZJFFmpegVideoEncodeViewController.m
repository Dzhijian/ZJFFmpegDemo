//
//  ZJFFmpegVideoEncodeViewController.m
//  ZJFFmpegDemo
//
//  Created by 邓志坚 on 2018/9/28.
//  Copyright © 2018 邓志坚. All rights reserved.
//

#import "ZJFFmpegVideoEncodeViewController.h"
#import <libavcodec/avcodec.h>
#import <libavutil/imgutils.h>
#import <libavformat/avformat.h>
@interface ZJFFmpegVideoEncodeViewController ()

@end

@implementation ZJFFmpegVideoEncodeViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.navigationItem.title = @"FFmpeg 视频编码";
    //文件准备
    
    NSString* inPath = [[NSBundle mainBundle] pathForResource:@"video1" ofType:@"yuv"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         
                                                         NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *tmpPath = [path stringByAppendingPathComponent:@"temp"];
    [[NSFileManager defaultManager] createDirectoryAtPath:tmpPath withIntermediateDirectories:YES attributes:nil error:NULL];
    NSString* outFilePath = [tmpPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Test.h264"]];
    
    
    //第一步：注册组件
    av_register_all();
    //第二步：初始化封装格式上下文
    AVFormatContext* avformat_context = avformat_alloc_context();
    //推测输出文件类型（视频压缩数据格式类型）
    const char* outFilePathChar = [outFilePath UTF8String];
    //得到视频压缩数据格式（h264,h265,mpeg2等等）
    AVOutputFormat* avoutput_format = av_guess_format(NULL, outFilePathChar, NULL);
    //指定类型,必不可少的一步
    avformat_context->oformat = avoutput_format;
    //第三步：打开输出文件
    if (avio_open(&avformat_context->pb, outFilePathChar, AVIO_FLAG_WRITE)<0) {
        NSLog(@"打开输出文件失败");
        return;
    }
    //第四步：创建输出码流（视频流 ）
    AVStream* av_video_stream = avformat_new_stream(avformat_context, NULL);//只是创建内存，目前不知道是什么类型的流，但是们希望是视频流
    
    //第五步：查找视频编码器
    
    //5.1 获取编码器上下文
    AVCodecContext* avcodec_context = av_video_stream->codec;
    //5.2 设置编码器上下文参数
    avcodec_context->codec_id = avoutput_format->video_codec;//设置编码器ID
    avcodec_context->codec_type = AVMEDIA_TYPE_VIDEO;//设置编码器类型
    avcodec_context->pix_fmt = AV_PIX_FMT_YUV420P;//设置读取像素数据格式（编码的是像素数据格式）,这个类型是根据解码的时候指定的视频像素数据格式类型
    //设置视频宽高
    avcodec_context->width = 640;
    avcodec_context->height = 352;
    //设置帧率
    //这里设置为每秒25帧 fps（f：frame 帧，ps：每秒）
    avcodec_context->time_base.num = 1;
    avcodec_context->time_base.den = 25;
    //设置码率（码率bps：单位时间内传输的二进制数据量）,码率也是比特率，比特率越高，传输速度越快
    //kbps:每秒传输千位
    avcodec_context->bit_rate = 468000;//码率 = 视频大小（bit）/时间（秒）。码率越大证明视频越大
    //设置GOP(GOP:画面组，一组连续的画面)，影响视频质量问题
    /**
     *MPEG格式画面类型:I帧，P帧，B帧
     *I帧:原始帧（原始视频数据，完整的画面），关键帧（必须要有，如果没有则不能进行编解码操作），视频的第一帧总是是I帧
     *P帧:向前预测帧（帧间预测编码帧）：预测前面一帧的类型，处理数据，前面一帧可能是I帧，也可能是B帧
     *B帧:前后预测帧（双向预测编码帧），B帧压缩率高，但同时对解码性能要求也高
     *I帧越少，视频越小。其实说白了。B 和 P 帧是对I帧的压缩处理，从而减小视频大小
     */
    avcodec_context->gop_size = 250;//每250帧插入一个I帧
    
    //设置量化参数.  量化系数越小，视频越清晰（这个量化参数都是些数学算法，有兴趣可以了解一下。），这里采用默认值。
    avcodec_context->qmin = 10;//最小量化系数
    avcodec_context->qmax = 51;//最大量化系数
    //设置B帧最大值
    avcodec_context->max_b_frames = 0;//不需要B帧
    
    //5.3 查找解码器（h264），默认情况下FFmpeg没有编译进行h264库，所以要编译h264库
    AVCodec* avcodec = avcodec_find_encoder(avcodec_context->codec_id);
    if (avcodec==NULL) {
        NSLog(@"找不到解码器");
        return;
    }
    NSLog(@"找到解码器:%s ",avcodec->name);
    
    //第六步：打开编码器，打开h264编码器
    //打开以前做一些编码延时问题优化。编码选项->编码设置
    AVDictionary *param = 0;
    if (avcodec_context->codec_id == AV_CODEC_ID_H264) {
        //需要查看x264源码->x264.c文件
        //第一个值：预备参数
        //key: preset
        //value: slow->慢
        //value: superfast->超快
        av_dict_set(&param, "preset", "slow", 0);
        //第二个值：调优
        //key: tune->调优
        //value: zerolatency->零延迟
        av_dict_set(&param, "tune", "zerolatency", 0);
    }
    if (avcodec_open2(avcodec_context, avcodec, &param) < 0) {
        NSLog(@"打开编码器失败");
        return;
    }
    
    //第七步：写入文件头信息
    avformat_write_header(avformat_context, NULL);
    
    //第八步：循环编码yuv文件（视频像素数据）->编码为视频压缩数据（h264格式）
    //8.1 定义一个缓冲区
    //作用：缓存一帧视频像素数据
    //8.1.1 获取缓冲区大小
    int buffer_size = av_image_get_buffer_size(avcodec_context->pix_fmt,
                                               avcodec_context->width,
                                               avcodec_context->height,
                                               1);
    
    //8.1.2 创建一个缓冲区
    int y_size = avcodec_context->width * avcodec_context->height;
    uint8_t *out_buffer = (uint8_t *) av_malloc(buffer_size);
    
    //8.1.3 打开输入文件
    const char *cinFilePath = [inPath UTF8String];
    FILE *in_file = fopen(cinFilePath, "rb");
    if (in_file == NULL) {
        NSLog(@"文件不存在");
        return;
    }
    
    //8.2.1 开辟一块内存空间->av_frame_alloc
    //开辟了一块内存空间
    AVFrame *av_frame = av_frame_alloc();
    //8.2.2 设置缓冲区和AVFrame类型保持一直->填充数据
    av_image_fill_arrays(av_frame->data,
                         av_frame->linesize,
                         out_buffer,
                         avcodec_context->pix_fmt,
                         avcodec_context->width,
                         avcodec_context->height,
                         1);
    
    int i = 0;
    
    //9.2 接收一帧视频像素数据->编码为->视频压缩数据格式
    AVPacket *av_packet = (AVPacket *) av_malloc(buffer_size);
    int result = 0;
    int current_frame_index = 1;
    while (true) {
        //8.1 从yuv文件里面读取缓冲区
        if (fread(out_buffer, 1, y_size * 3 / 2, in_file) <= 0) {
            NSLog(@"读取完毕...");
            break;
        } else if (feof(in_file)) {
            break;
        }
        
        //8.2 将缓冲区数据->转成AVFrame类型
        //给AVFrame填充数据
        //8.2.3 void * restrict->->转成->AVFrame->ffmpeg数据类型
        //Y值
        av_frame->data[0] = out_buffer;
        //U值
        av_frame->data[1] = out_buffer + y_size;
        //V值
        av_frame->data[2] = out_buffer + y_size * 5 / 4;
        av_frame->pts = i;
        //注意时间戳
        i++;
        //总结：这样一来我们的AVFrame就有数据了
        
        //第9步：视频编码处理
        //9.1 发送一帧视频像素数据
        avcodec_send_frame(avcodec_context, av_frame);
        //9.2 接收一帧视频像素数据->编码为->视频压缩数据格式
        result = avcodec_receive_packet(avcodec_context, av_packet);
        //9.3 判定是否编码成功
        if (result == 0) {
            //编码成功
            //第10步：将视频压缩数据->写入到输出文件中->outFilePath
            av_packet->stream_index = av_video_stream->index;
            result = av_write_frame(avformat_context, av_packet);
            NSLog(@"当前是第%d帧", current_frame_index);
            current_frame_index++;
            //是否输出成功
            if (result < 0) {
                NSLog(@"输出一帧数据失败");
                return;
            }
        }
    }
    
    //第11步：写入剩余帧数据->可能没有
    flush_encoder(avformat_context, 0);
    
    //第12步：写入文件尾部信息
    av_write_trailer(avformat_context);
    
    //第13步：释放内存
    avcodec_close(avcodec_context);
    av_free(av_frame);
    av_free(out_buffer);
    av_packet_free(&av_packet);
    avio_close(avformat_context->pb);
    avformat_free_context(avformat_context);
    fclose(in_file);
}

int flush_encoder(AVFormatContext *fmt_ctx, unsigned int stream_index) {
    int ret;
    int got_frame;
    AVPacket enc_pkt;
    if (!(fmt_ctx->streams[stream_index]->codec->codec->capabilities &
          CODEC_CAP_DELAY))
    return 0;
    while (1) {
        enc_pkt.data = NULL;
        enc_pkt.size = 0;
        av_init_packet(&enc_pkt);
        ret = avcodec_encode_video2(fmt_ctx->streams[stream_index]->codec, &enc_pkt,
                                    NULL, &got_frame);
        av_frame_free(NULL);
        if (ret < 0)
        break;
        if (!got_frame) {
            ret = 0;
            break;
        }
        NSLog(@"Flush Encoder: Succeed to encode 1 frame!\tsize:%5d\n", enc_pkt.size);
        /* mux encoded frame */
        ret = av_write_frame(fmt_ctx, &enc_pkt);
        if (ret < 0)
        break;
    }
    return ret;
}


@end
