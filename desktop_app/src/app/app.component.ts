import {
  Component,
  OnInit,
  NgZone,
  AfterViewInit,
  ViewChild,
  ElementRef,
  Renderer2,
  EventEmitter,
} from '@angular/core';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css'],
})
export class AppComponent {
  title = 'Indoor Localization';
  canvasWidth: number = 700;
  canvasHeight: number = 400;
  mapWidth: number = 700;
  mapHeight: number = 400;
  previousPositionX: number = 0;
  previousPositionY: number = 0;
  positionX: number = 5;
  positionY: number = 5;
  ratio: number = 10;
  radius: number = 8;
  location: string[];
  source: EventSource;
  sourceCreated: boolean = false;
  @ViewChild('x') animationX: ElementRef;
  @ViewChild('y') animationY: ElementRef;

  constructor(public ngZone: NgZone) {}

  onResize(event) {
    this.canvasWidth = window.innerWidth - 100;
    this.canvasHeight = window.innerHeight - 100;
    this.mapWidth = window.innerWidth - 100;
    this.mapHeight = window.innerHeight - 100;
  }

  getLocation() {
    let circle = document.getElementById('position');
    this.source = new EventSource('http://172.28.129.11:8080/');
    this.source.onmessage = (event) => {
      this.location = event.data.split(',');
      this.ngZone.run(() => {
        this.previousPositionX = this.positionX;
        this.previousPositionY = this.positionY;
        this.positionX = +this.location[0] * this.canvasWidth + this.radius;
        this.positionY = +this.location[1] * this.canvasHeight + this.radius;
        this.animationX.nativeElement.beginElement();
        this.animationY.nativeElement.beginElement();
      });
    };
  }

  stopExchangeUpdates() {
    this.source.close();
    this.source = null;
  }
}
