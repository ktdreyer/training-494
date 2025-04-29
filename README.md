This repository has a test script to interactively debug CI problems in instructlab's training repository. Originally it was for [this older issue](https://github.com/instructlab/training/issues/494), and now it is for:

https://github.com/instructlab/instructlab/issues/3321

In lieu of learning+using https://github.com/nektos/act , I translated https://github.com/instructlab/training/actions/workflows/e2e-nvidia-l40s-x4.yml into a series of shell methods so I can step through them live on a node in tmux.
