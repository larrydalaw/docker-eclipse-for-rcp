FROM dockerfile/java:oracle-java8

MAINTAINER Joerg Matysiak

# Please adjust values of USERNAME, uid and gid if needed 

ENV USERNAME developer

# Replace 1000 with your user / group id
RUN export uid=1000 gid=1000 && \
    mkdir -p /home/$USERNAME && \
    echo "$USERNAME:x:${uid}:${gid}:Developer,,,:/home/$USERNAME:/bin/bash" >> /etc/passwd && \
    echo "$USERNAME:x:${uid}:" >> /etc/group && \
    echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME && \
    chown ${uid}:${gid} -R /home/$USERNAME


USER $USERNAME
ENV HOME /home/$USERNAME

WORKDIR $HOME

# Install missing packages
RUN sudo apt-get update
RUN sudo apt-get install libswt-gtk-3-java unzip ant ant-contrib git -y

ENV ECLIPSE_DOWNLOAD_URL http://ftp-stud.fht-esslingen.de/pub/Mirrors/eclipse/technology/epp/downloads/release/luna/SR1a/eclipse-rcp-luna-SR1a-linux-gtk-x86_64.tar.gz 
# Download Eclipse for RCP and RAP developers
RUN curl $ECLIPSE_DOWNLOAD_URL | tar -xvz

# Fix Eclipse Classcast Exception at startup
# see http://stackoverflow.com/questions/26279570/getting-rid-of-org-eclipse-osgi-internal-framework-equinoxconfiguration1-that-c
#
RUN echo "-Dosgi.configuration.area.default=null" >> $HOME/eclipse/eclipse.ini && \
    echo "-Dosgi.user.area.default=null" >> $HOME/eclipse/eclipse.ini && \
    echo "-Dosgi.user.area=@user.home" >> $HOME/eclipse/eclipse.ini &&\
    echo "-Dosgi.instance.area.default=null" >> $HOME/eclipse/eclipse.ini

# Remove MaxPermSize parameter from eclipse.ini. 
# (This parameter is no longer supported with Java 8)
RUN grep -v -e "MaxPermSize" -e "256m" $HOME/eclipse/eclipse.ini > $HOME/eclipse/eclipse.ini.new; mv $HOME/eclipse/eclipse.ini.new $HOME/eclipse/eclipse.ini 

ENV ECLIPSE_INSTALL_CALL_PREFIX $HOME/eclipse/eclipse -clean -purgeHistory -application org.eclipse.equinox.p2.director -noSplash 
ENV ECLIPSE_INSTALL_CALL_POSTFIX -vmargs -Declipse.p2.mirrors=true -Djava.net.preferIPv4Stack=true

# Install Findbugs
RUN $ECLIPSE_INSTALL_CALL_PREFIX \
    -repository http://findbugs.cs.umd.edu/eclipse \
    -installIUs edu.umd.cs.findbugs.plugin.eclipse \
    $ECLIPSE_INSTALL_CALL_POSTFIX

# Install Checkstyle
RUN $ECLIPSE_INSTALL_CALL_PREFIX \
    -repository http://eclipse-cs.sourceforge.net/update \
    -installIUs net.sf.eclipsecs.ui \
    $ECLIPSE_INSTALL_CALL_POSTFIX

# Install Database Viewer
RUN $ECLIPSE_INSTALL_CALL_PREFIX \
    -repository http://www.ne.jp/asahi/zigen/home/plugin/dbviewer/ \
    -installIUs zigen.plugin.db \
    $ECLIPSE_INSTALL_CALL_POSTFIX

# Install Memory Analyzer
RUN $ECLIPSE_INSTALL_CALL_PREFIX \
    -repository http://download.eclipse.org/mat/1.4/update-site/ \
    -installIUs org.eclipse.mat.ui,org.eclipse.mat.report,org.eclipse.mat.ui.help \
    $ECLIPSE_INSTALL_CALL_POSTFIX

# Install QuickREx (as dropin)
RUN cd $HOME/eclipse/dropins && curl -L -O http://sourceforge.net/projects/quickrex/files/latest/download/QuickREx_3.5.0.jar

# Install WicketShell
RUN $ECLIPSE_INSTALL_CALL_PREFIX \
    -repository http://www.wickedshell.net/updatesite \
    -installIUs net.sf.wickedshell.ui,net.sf.wickedshell.shell \
    $ECLIPSE_INSTALL_CALL_POSTFIX

# Install latest gradle
ENV GRADLE_DOWNLOAD_LINK https://services.gradle.org/distributions/gradle-2.2.1-bin.zip
RUN curl -L  -o gradle.zip $GRADLE_DOWNLOAD_LINK && \
     sudo unzip gradle.zip -d /opt && \
     rm gradle.zip && \
     sudo update-alternatives --install /usr/bin/gradle gradle /opt/gradle*/bin/gradle 100 

###
### TODO: fix gradle tooling
###

# Install Eclipse gradle tooling (needs antlr and protobuf-dt)
#RUN $ECLIPSE_INSTALL_CALL_PREFIX \
#    -repository http://download.eclipse.org/modeling/tmf/xtext/updates/composite/releases/ \
#    -installIUs org.antlr.runtime,org.eclipse.emf.codegen.ecore.xtext\
#    $ECLIPSE_INSTALL_CALL_POSTFIX



#RUN $ECLIPSE_INSTALL_CALL_PREFIX \
#    -repository http://protobuf-dt.googlecode.com/git/update-site \
#    -installIUs com.google.eclipse.protobuf,com.google.eclipse.protobuf.ui \
#    $ECLIPSE_INSTALL_CALL_POSTFIX

#RUN $ECLIPSE_INSTALL_CALL_PREFIX \
#    -repository http://dist.springsource.com/release/TOOLS/gradle \
#    -installIUs org.springframework.ide.eclipse.uaa,org.springsource.ide.eclipse.gradle.ui,org.springsource.ide.eclipse.gradle.ui.taskview \
#    $ECLIPSE_INSTALL_CALL_POSTFIX

CMD $HOME/eclipse/eclipse
