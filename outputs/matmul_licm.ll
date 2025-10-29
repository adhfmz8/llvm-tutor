; ModuleID = 'test-inputs/matmul-canonical.ll'
source_filename = "matmul.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx14.0.0"

@.str = private unnamed_addr constant [4 x i8] c"%f\0A\00", align 1

; Function Attrs: noinline nounwind ssp uwtable(sync)
define void @matmul(ptr noundef %0, ptr noundef %1, ptr noundef %2) #0 {
  br label %4

4:                                                ; preds = %30, %3
  %.037 = phi i32 [ 0, %3 ], [ %31, %30 ]
  %5 = sext i32 %.037 to i64
  %6 = sext i32 %.037 to i64
  %7 = getelementptr inbounds [512 x double], ptr %2, i64 %6
  %8 = getelementptr inbounds [512 x double], ptr %0, i64 %5
  br label %9

9:                                                ; preds = %26, %4
  %.026 = phi i32 [ 0, %4 ], [ %27, %26 ]
  %10 = sext i32 %.026 to i64
  br label %11

11:                                               ; preds = %20, %9
  %.05 = phi i32 [ 0, %9 ], [ %21, %20 ]
  %.014 = phi double [ 0.000000e+00, %9 ], [ %19, %20 ]
  %12 = sext i32 %.05 to i64
  %13 = getelementptr inbounds [512 x double], ptr %8, i64 0, i64 %12
  %14 = load double, ptr %13, align 8
  %15 = sext i32 %.05 to i64
  %16 = getelementptr inbounds [512 x double], ptr %1, i64 %15
  %17 = getelementptr inbounds [512 x double], ptr %16, i64 0, i64 %10
  %18 = load double, ptr %17, align 8
  %19 = call double @llvm.fmuladd.f64(double %14, double %18, double %.014)
  br label %20

20:                                               ; preds = %11
  %21 = add nsw i32 %.05, 1
  %22 = icmp slt i32 %21, 512
  br i1 %22, label %11, label %23, !llvm.loop !5

23:                                               ; preds = %20
  %.01.lcssa = phi double [ %19, %20 ]
  %24 = sext i32 %.026 to i64
  %25 = getelementptr inbounds [512 x double], ptr %7, i64 0, i64 %24
  store double %.01.lcssa, ptr %25, align 8
  br label %26

26:                                               ; preds = %23
  %27 = add nsw i32 %.026, 1
  %28 = icmp slt i32 %27, 512
  br i1 %28, label %9, label %29, !llvm.loop !7

29:                                               ; preds = %26
  br label %30

30:                                               ; preds = %29
  %31 = add nsw i32 %.037, 1
  %32 = icmp slt i32 %31, 512
  br i1 %32, label %4, label %33, !llvm.loop !8

33:                                               ; preds = %30
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #1

; Function Attrs: noinline nounwind ssp uwtable(sync)
define i32 @main() #0 {
  %1 = alloca [512 x [512 x double]], align 8
  %2 = alloca [512 x [512 x double]], align 8
  %3 = alloca [512 x [512 x double]], align 8
  br label %4

4:                                                ; preds = %22, %0
  %.013 = phi i32 [ 0, %0 ], [ %23, %22 ]
  %5 = sext i32 %.013 to i64
  %6 = sext i32 %.013 to i64
  %7 = getelementptr inbounds [512 x [512 x double]], ptr %2, i64 0, i64 %6
  %8 = getelementptr inbounds [512 x [512 x double]], ptr %1, i64 0, i64 %5
  br label %9

9:                                                ; preds = %18, %4
  %.02 = phi i32 [ 0, %4 ], [ %19, %18 ]
  %10 = add nsw i32 %.013, %.02
  %11 = sitofp i32 %10 to double
  %12 = sext i32 %.02 to i64
  %13 = getelementptr inbounds [512 x double], ptr %8, i64 0, i64 %12
  store double %11, ptr %13, align 8
  %14 = sub nsw i32 %.013, %.02
  %15 = sitofp i32 %14 to double
  %16 = sext i32 %.02 to i64
  %17 = getelementptr inbounds [512 x double], ptr %7, i64 0, i64 %16
  store double %15, ptr %17, align 8
  br label %18

18:                                               ; preds = %9
  %19 = add nsw i32 %.02, 1
  %20 = icmp slt i32 %19, 512
  br i1 %20, label %9, label %21, !llvm.loop !9

21:                                               ; preds = %18
  br label %22

22:                                               ; preds = %21
  %23 = add nsw i32 %.013, 1
  %24 = icmp slt i32 %23, 512
  br i1 %24, label %4, label %25, !llvm.loop !10

25:                                               ; preds = %22
  %26 = getelementptr inbounds [512 x [512 x double]], ptr %1, i64 0, i64 0
  %27 = getelementptr inbounds [512 x [512 x double]], ptr %2, i64 0, i64 0
  %28 = getelementptr inbounds [512 x [512 x double]], ptr %3, i64 0, i64 0
  call void @matmul(ptr noundef %26, ptr noundef %27, ptr noundef %28)
  %29 = getelementptr inbounds [512 x [512 x double]], ptr %3, i64 0, i64 511
  %30 = getelementptr inbounds [512 x double], ptr %29, i64 0, i64 511
  %31 = load double, ptr %30, align 8
  %32 = call i32 (ptr, ...) @printf(ptr noundef @.str, double noundef %31)
  ret i32 0
}

declare i32 @printf(ptr noundef, ...) #2

attributes #0 = { noinline nounwind ssp uwtable(sync) "frame-pointer"="non-leaf" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8.5a,+v8a,+zcm,+zcz" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { "frame-pointer"="non-leaf" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+v8.1a,+v8.2a,+v8.3a,+v8.4a,+v8.5a,+v8a,+zcm,+zcz" }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"uwtable", i32 1}
!3 = !{i32 7, !"frame-pointer", i32 1}
!4 = !{!"Homebrew clang version 17.0.6"}
!5 = distinct !{!5, !6}
!6 = !{!"llvm.loop.mustprogress"}
!7 = distinct !{!7, !6}
!8 = distinct !{!8, !6}
!9 = distinct !{!9, !6}
!10 = distinct !{!10, !6}
